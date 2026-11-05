// lib/widgets/profile_setup_dialog.dart
//
// 「あなたのことを教えてください」：プロフィール YAML の入力画面
// - YAML を指定せずに起動したときだけ出す（HomePage から呼ぶ）
// - 最初に入力方法を選ぶ：
//   ・Excel（スキルシート）… Excel テンプレートを名前を付けて保存 → Excel で編集 → 選択すると、
//     中身から YAML（プロフィール＋Work / Private）を作って確かめる（lib/utils/skill_sheet.dart）。作った YAML は保存もできる
//   ・YAML / Markdown … これまでどおり（以下）
// - できること：テンプレートを名前を付けて保存・コピー ／ ファイルを選択・テキストを貼り付け（その場で形式を確認）／
//   アップロード（確認画面で中身を見て OK のときだけ。反映中は全画面ローディング）／ ⓘ で書き方の説明（説明だけ）
// - 正しい YAML を読み込むまで閉じられない（外側のタップ・Esc・戻るでも閉じない）
// - ファイルに work / private も書かれていれば一緒に読み込む（Skills / Projects も切り替わり、2 回目のアップロードは要らない）
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import '../utils/profile_store.dart';
import '../utils/profile_bundle.dart';
import '../utils/projects_diff.dart';
import '../utils/data_format.dart';
import '../utils/browser/browser.dart';
import '../utils/work_yaml_loader.dart';
import '../utils/private_yaml_loader.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../utils/skill_sheet.dart';
import '../utils/file_saver.dart';
import '../utils/asset_text.dart';
import 'app_segment.dart';
import 'upload_parts.dart';

/// 入力方法
enum _InputMethod { excel, text }

/// 入力画面を出す（読み込みが終わると閉じる）
/// プロフィールのファイルに Work / Private も書かれていれば一緒に読み込み、[onProjectsChanged]
/// （Skills / Projects の作り直し）を呼ぶ。2 回目以降のアップロードは要らない
Future<void> showProfileSetupDialog(BuildContext context, {VoidCallback? onProjectsChanged}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // 外側をタップしても閉じない
    builder: (_) => PopScope(
      canPop: false, // Esc・ブラウザの戻るでも閉じない
      child: _ProfileSetupDialog(onProjectsChanged: onProjectsChanged),
    ),
  );
}

class _ProfileSetupDialog extends StatefulWidget {
  final VoidCallback? onProjectsChanged;

  const _ProfileSetupDialog({this.onProjectsChanged});

  @override
  State<_ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends State<_ProfileSetupDialog> {
  bool _picking = false;
  String? _fileName;
  /// 読み込めるときだけ入る（プロフィール＋一緒に書かれた Work / Private）
  ProfileBundle? _bundle;
  List<String> _errors = const [];

  /// 前に貼り付けたテキスト（もう一度開いたときに続きから直せるように）
  String _pasted = '';

  /// 保存・コピーするテンプレートの形式
  DataFormat _templateFormat = DataFormat.yaml;

  /// 入力方法（Excel / YAML・Markdown）
  _InputMethod _method = _InputMethod.text;

  /// Excel から作った YAML（読み込めるときだけ。「作った YAML を保存」で使う）
  String? _generatedYaml;

  /// 入力方法を切り替える（選んでいたファイルは取り消す）
  void _switchMethod(_InputMethod method) {
    if (method == _method) return;
    setState(() {
      _method = method;
      _fileName = null;
      _bundle = null;
      _errors = const [];
      _generatedYaml = null;
    });
  }

  /// Excel：テンプレートを名前を付けて保存する
  Future<void> _saveExcelTemplate() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await loadAssetBytes(skillSheetTemplateAsset);
      final result = await FileSaver.saveBytesAs(
        fileName: skillSheetTemplateFileName,
        bytes: bytes,
        description: ExcelTexts.excelFileDescription,
        mimeType: skillSheetMimeType,
        extensions: const ['.xlsx'],
      );
      if (result == FileSaveResult.saved) {
        messenger.showSnackBar(
            SnackBar(content: Text(AppTexts.formatSaved(skillSheetTemplateFileName))));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(AppTexts.downloadFailed(e))));
    }
  }

  /// Excel：ファイルを選ぶ → 中身から YAML を作り、YAML / Markdown と同じく確かめる
  Future<void> _pickExcel() async {
    setState(() => _picking = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: skillSheetExtensions,
        withData: true,
      );
      final file = picked?.files.single;
      if (file == null || file.bytes == null) return; // キャンセル（前の選択はそのまま）

      if (!isSkillSheetFile(file.name)) {
        setState(() {
          _fileName = file.name;
          _bundle = null;
          _generatedYaml = null;
          _errors = [ExcelTexts.extensionOnly];
        });
        return;
      }

      final result = convertSkillSheet(file.bytes!, fileName: file.name);
      final bundle = result.isOk
          ? readProfileBundle(result.yamlText!, fileName: skillSheetYamlName(file.name))
          : null;
      setState(() {
        _fileName = file.name;
        _bundle = bundle != null && bundle.isOk ? bundle : null;
        _generatedYaml = _bundle != null ? result.yamlText : null;
        _errors = bundle?.errors ?? result.errors;
      });
    } catch (e) {
      setState(() {
        _bundle = null;
        _generatedYaml = null;
        _errors = [AppTexts.fileReadFailed(e)];
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// Excel から作った YAML を保存する（次回は tool/run.dart で指定して起動できる）
  Future<void> _saveGeneratedYaml() async {
    final yaml = _generatedYaml;
    final source = _fileName;
    if (yaml == null || source == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final name = skillSheetYamlName(source);
    try {
      final result = await FileSaver.saveTextAs(
        fileName: name,
        text: yaml,
        description: AppTexts.yamlFileDescription,
        mimeType: 'text/yaml',
        extensions: const ['.yaml', '.yml'],
      );
      if (result == FileSaveResult.saved) {
        messenger.showSnackBar(SnackBar(content: Text(AppTexts.formatSaved(name))));
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(AppTexts.downloadFailed(e))));
    }
  }

  /// 1. ファイルを選ぶ → その場で形式を確かめる（間違っていればアップロードできない）
  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: acceptedExtensions, // .yaml / .yml / .md / .markdown 以外は選べない
        withData: true,
      );
      final file = picked?.files.single;
      if (file == null || file.bytes == null) return; // キャンセル（前の選択はそのまま）

      if (!hasAcceptedExtension(file.name)) {
        setState(() {
          _fileName = file.name;
          _bundle = null;
          _errors = [ProfileTexts.extensionOnly];
        });
        return;
      }

      _apply(utf8.decode(file.bytes!), fileName: file.name);
    } catch (e) {
      setState(() {
        _bundle = null;
        _errors = [AppTexts.fileReadFailed(e)];
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// 読み込んだテキスト（ファイル・貼り付け共通）の形式を確かめて、状態に反映する
  /// - YAML / Markdown を見分け、Markdown は同じ中身の JSON（＝YAML として読める）に変えてから確かめる
  /// - work / private も書かれていれば、Work / Private として一緒に確かめる
  /// - [fileName] がなければ貼り付けたテキスト（形式は中身から見分ける）
  void _apply(String text, {String? fileName}) {
    final bundle = readProfileBundle(text, fileName: fileName);
    setState(() {
      _fileName = fileName ??
          AppTexts.sourceWithFormat(
            AppTexts.pastedTextName,
            bundle.format == DataFormat.markdown ? AppTexts.formatMarkdown : AppTexts.formatYaml,
          );
      _bundle = bundle.isOk ? bundle : null;
      if (fileName == null) _pasted = text; // 貼り付けた元のテキスト（次に開いたとき用）
      _errors = bundle.errors;
    });
  }

  /// 1'. テキストを貼り付ける（ファイルを選べない人向け）→ ファイルと同じく形式を確かめる
  Future<void> _paste() async {
    final text = await showPasteYamlDialog(context, initialText: _pasted);
    if (text == null || !mounted) return; // キャンセル
    _apply(text);
  }

  /// 2. 確認画面 → OK なら 3. 全画面ローディングを出して反映
  Future<void> _upload() async {
    final bundle = _bundle;
    if (bundle == null) return;
    final hasProjects = bundle.workText != null || bundle.privateText != null;

    final ok = await confirmUpload(
      context,
      fileName: _fileName!,
      replaceTarget: hasProjects
          ? '${ProfileTexts.replaceTarget}・${BundleTexts.includes(bundle.workCount, bundle.privateCount)}'
          : ProfileTexts.replaceTarget,
      summary: _ProfileSummary(bundle: bundle),
    );
    if (!ok || !mounted) return;

    // 一緒に書いた Work / Private が今表示している内容と違えば、上書きしてよいかを確かめる
    final diffs = <(String, ProjectsDiff)>[
      if (bundle.workText != null)
        (AppTexts.work, diffProjects(await WorkYamlLoader.loadYamlString(), bundle.workText!)),
      if (bundle.privateText != null)
        (AppTexts.private, diffProjects(await PrivateYamlLoader.loadYamlString(), bundle.privateText!)),
    ];
    if (!mounted) return;
    final overwrite = await confirmOverwrite(context, diffs: diffs);
    if (!overwrite || !mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop(); // 入力画面を閉じる（PopScope は戻る操作だけを止めるので、ここでは閉じられる）

    await runReloading(navigator, () async {
      ProfileStore.instance.setUploaded(bundle.profileText!, bundle.profile!);
      // Work / Private も書かれていれば、それぞれのアップロードと同じくセッションに保存して読み直す
      if (bundle.workText != null) SessionStore.write('work', bundle.workText!);
      if (bundle.privateText != null) SessionStore.write('private', bundle.privateText!);
      if (hasProjects) {
        widget.onProjectsChanged?.call();
        await Future.wait([WorkYamlLoader.loadYamlString(), PrivateYamlLoader.loadYamlString()]);
      }
    });

    messenger.showSnackBar(const SnackBar(content: Text(ProfileTexts.uploaded)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final startupErrors = ProfileStore.instance.startupErrors;
    final isExcel = _method == _InputMethod.excel;

    return AlertDialog(
      backgroundColor: colors.dialogBackground,
      icon: Icon(Icons.badge_outlined, color: colors.primary),
      title: Row(
        children: [
          // ⓘ と左右のバランスを取るための空き
          const SizedBox(width: AppSizes.profileHelpButtonSize),
          Expanded(
            child: Text(
              ProfileTexts.setupTitle,
              textAlign: TextAlign.center,
              style: AppStyles.dialogTitle(context),
            ),
          ),
          SizedBox(
            width: AppSizes.profileHelpButtonSize,
            child: IconButton(
              icon: Icon(Icons.info_outline, color: colors.textSecondary),
              tooltip: ProfileTexts.helpTooltip,
              onPressed: () => showProfileHelp(context),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: AppSizes.uploadDialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ProfileTexts.setupLead, style: AppStyles.dialogBody(context)),
              const SizedBox(height: AppSizes.space16),

              // 入力方法（狭い画面では縮めて 1 行に収める）
              Text(ExcelTexts.methodLabel, style: AppStyles.filterGroupLabel(context)),
              const SizedBox(height: AppSizes.space6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: AppSegment<_InputMethod>(
                  value: _method,
                  onChanged: _switchMethod,
                  items: const [
                    AppSegmentItem(value: _InputMethod.excel, label: ExcelTexts.methodExcel),
                    AppSegmentItem(value: _InputMethod.text, label: ExcelTexts.methodText),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.space16),

              UploadSteps(steps: isExcel ? ExcelTexts.steps : ProfileTexts.setupSteps),
              const SizedBox(height: AppSizes.space8),

              // 起動時に指定した YAML が読めなかった理由（ファイルを選ぶまで出す）
              if (_fileName == null && startupErrors.isNotEmpty) ...[
                Text(
                  ProfileTexts.startupFailedTitle,
                  style: AppStyles.dialogError(context).copyWith(fontWeight: FontWeight.w600),
                ),
                for (final e in startupErrors)
                  Text('${AppTexts.bullet}$e', style: AppStyles.dialogError(context)),
                const SizedBox(height: AppSizes.space8),
              ],

              if (isExcel)
                _ExcelSourcePanel(
                  onSaveTemplate: _saveExcelTemplate,
                  onPickFile: _picking ? null : _pickExcel,
                  hasSource: _fileName != null,
                )
              else
                UploadSourcePanel(
                  templateFormat: _templateFormat,
                  onTemplateFormatChanged: (f) => setState(() => _templateFormat = f),
                  onSaveTemplate: () =>
                      saveTemplateFile(context, kind: DataKind.profile, format: _templateFormat),
                  onCopyTemplate: () => copyTemplateText(
                    context,
                    assetPath: templateAssetPath(DataKind.profile, _templateFormat),
                    fileName: templateFileName(DataKind.profile, _templateFormat),
                  ),
                  onPickFile: _picking ? null : _pick,
                  onPasteText: _picking ? null : _paste,
                  hasSource: _fileName != null,
                ),
              const SizedBox(height: AppSizes.space12),
              SelectedFileStatus(fileName: _fileName, errors: _errors),
              // Work / Private も一緒に書かれていれば、それも読み込むことを知らせる
              if (_bundle != null &&
                  (_bundle!.workText != null || _bundle!.privateText != null)) ...[
                const SizedBox(height: AppSizes.space8),
                Row(
                  children: [
                    Icon(Icons.library_add_check_outlined,
                        size: AppSizes.space20, color: colors.primary),
                    const SizedBox(width: AppSizes.space8),
                    Expanded(
                      child: Text(
                        BundleTexts.alsoLoads(
                          BundleTexts.includes(_bundle!.workCount, _bundle!.privateCount),
                        ),
                        style: AppStyles.helpBody(context),
                      ),
                    ),
                  ],
                ),
              ],
              // Excel から作った YAML を保存（次回はこの YAML を指定して起動できる）
              if (isExcel && _generatedYaml != null) ...[
                const SizedBox(height: AppSizes.space8),
                TextButton.icon(
                  onPressed: _saveGeneratedYaml,
                  icon: const Icon(Icons.save_alt),
                  label: const Text(ExcelTexts.saveYaml),
                ),
                Text(ExcelTexts.saveYamlNote, style: AppStyles.helpBody(context)),
              ],
              const SizedBox(height: AppSizes.space16),

              // 次回の起動方法
              Text(ProfileTexts.setupNextTime, style: AppStyles.helpBody(context)),
              const SizedBox(height: AppSizes.space6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.space10),
                decoration: AppStyles.codeBlock(context),
                child: SelectableText(ProfileTexts.runCommand,
                    style: AppStyles.codeText(context)),
              ),
            ],
          ),
        ),
      ),
      actionsOverflowButtonSpacing: AppSizes.space8,
      actions: [
        // 正しい YAML を読み込むまで押せない
        FilledButton.icon(
          onPressed: _bundle == null || _picking ? null : _upload,
          icon: const Icon(Icons.upload_file),
          label: const Text(AppTexts.upload),
        ),
      ],
    );
  }
}

/// 確認画面の中身：プロフィールの各項目
class _ProfileSummary extends StatelessWidget {
  final ProfileBundle bundle;

  const _ProfileSummary({required this.bundle});

  /// 一緒に読み込む Work / Private のタイトル一覧
  List<Widget> _projects(BuildContext context, String label, String? text) {
    if (text == null) return const [];
    final projects = (loadYaml(text) as YamlMap)['projects'] as YamlList;
    return [
      const Divider(height: AppSizes.space24),
      Text(BundleTexts.confirmSection(label, projects.length), style: AppStyles.helpHeading(context)),
      const SizedBox(height: AppSizes.space8),
      for (var i = 0; i < projects.length; i++)
        Text('${i + 1}. ${projects[i]['title']}', style: AppStyles.helpBody(context)),
    ];
  }

  /// 「分類: A, B」の行
  static String _tech(Map<String, List<String>> tech) =>
      tech.entries.map((e) => '${e.key}: ${e.value.join(', ')}').join('\n');

  @override
  Widget build(BuildContext context) {
    final profile = bundle.profile!;
    final card = profile.card.entries
        .map((e) => '${e.key}: ${e.value is List ? (e.value as List).join(', ') : e.value}')
        .join('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ProfileTexts.confirmHome, style: AppStyles.helpHeading(context)),
        const SizedBox(height: AppSizes.space8),
        ConfirmField(ProfileTexts.fieldName, profile.name),
        ConfirmField(ProfileTexts.fieldRole, profile.role),
        ConfirmField(ProfileTexts.fieldTagline, profile.tagline),
        ConfirmField(ProfileTexts.fieldCard, card),
        const Divider(height: AppSizes.space24),
        Text(ProfileTexts.confirmAbout, style: AppStyles.helpHeading(context)),
        const SizedBox(height: AppSizes.space8),
        ConfirmField(ProfileTexts.fieldIntro, profile.intro),
        ConfirmField(AboutContent.domainsLabel, profile.domains.join(' / ')),
        ConfirmField(AboutContent.strengthsLabel, profile.strengths),
        ConfirmField(AboutContent.styleLabel, profile.style),
        ConfirmField(ProfileTexts.fieldClosing, profile.closing),
        ConfirmField(AboutContent.recentLabel, profile.recent),
        ConfirmField(ProfileTexts.fieldRecentTech, _tech(profile.recentTech)),
        ConfirmField(AboutContent.pastLabel, profile.past),
        ConfirmField(ProfileTexts.fieldPastTech, _tech(profile.pastTech)),
        ..._projects(context, AppTexts.work, bundle.workText),
        ..._projects(context, AppTexts.private, bundle.privateText),
      ],
    );
  }
}

/// Excel（スキルシート）のときのボタン群と、読み取る項目の説明
/// - テンプレート：［Excel テンプレートを保存］
/// - スキルシートを読み込む：［Excel を選択］
class _ExcelSourcePanel extends StatelessWidget {
  final VoidCallback onSaveTemplate;
  final VoidCallback? onPickFile; // null のときは押せない（読み込み中）
  final bool hasSource;

  const _ExcelSourcePanel({
    required this.onSaveTemplate,
    required this.onPickFile,
    required this.hasSource,
  });

  @override
  Widget build(BuildContext context) {
    Widget group(String title, Widget button) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppStyles.filterGroupLabel(context)),
            const SizedBox(height: AppSizes.space6),
            button,
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        group(
          AppTexts.templateGroup,
          TextButton.icon(
            onPressed: onSaveTemplate,
            icon: const Icon(Icons.save_alt),
            label: const Text(ExcelTexts.saveTemplate),
          ),
        ),
        const SizedBox(height: AppSizes.space12),
        group(
          ExcelTexts.inputGroup,
          OutlinedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.table_view_outlined),
            label: Text(hasSource ? ExcelTexts.chooseAnotherExcel : ExcelTexts.chooseExcel),
          ),
        ),
        const SizedBox(height: AppSizes.space12),
        Text(ExcelTexts.howItMaps, style: AppStyles.filterGroupLabel(context)),
        const SizedBox(height: AppSizes.space4),
        for (final m in ExcelTexts.mapping)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space4),
            child: Text('${AppTexts.bullet}$m', style: AppStyles.helpBody(context)),
          ),
      ],
    );
  }
}

/// ⓘ：書き方の説明だけ（テンプレートの保存は入力画面の 1 か所だけ）
void showProfileHelp(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (context) {
      final colors = context.colors;
      return AlertDialog(
        backgroundColor: colors.dialogBackground,
        title: Text(ProfileTexts.helpTitle, style: AppStyles.dialogTitle(context)),
        content: SizedBox(
          width: AppSizes.helpDialogWidth,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ProfileTexts.helpRules, style: AppStyles.helpHeading(context)),
                const SizedBox(height: AppSizes.space6),
                for (final r in ProfileTexts.helpRuleList)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.space4),
                    child: Text('${AppTexts.bullet}$r', style: AppStyles.helpBody(context)),
                  ),
                const SizedBox(height: AppSizes.space16),

                Text(ProfileTexts.helpFields, style: AppStyles.helpHeading(context)),
                const SizedBox(height: AppSizes.space6),
                for (final (key, required, note) in ProfileTexts.helpFieldList)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.space8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(TextSpan(children: [
                          TextSpan(
                            text: key,
                            style: AppStyles.codeText(context)
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '  ${required ? ProfileTexts.required : ProfileTexts.optional}',
                            style: required
                                ? AppStyles.helpEmphasis(context)
                                : AppStyles.helpBody(context),
                          ),
                        ])),
                        Padding(
                          padding: const EdgeInsets.only(left: AppSizes.space12),
                          child: Text(note, style: AppStyles.helpBody(context)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: AppSizes.space8),

                // Work / Private も一緒に
                Text(ProfileTexts.helpBundleTitle, style: AppStyles.helpHeading(context)),
                const SizedBox(height: AppSizes.space6),
                for (final r in ProfileTexts.helpBundleRules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.space4),
                    child: Text('${AppTexts.bullet}$r', style: AppStyles.helpBody(context)),
                  ),
                const SizedBox(height: AppSizes.space16),

                // Markdown で書く場合
                Text(ProfileTexts.helpMarkdownTitle, style: AppStyles.helpHeading(context)),
                const SizedBox(height: AppSizes.space6),
                for (final r in ProfileTexts.helpMarkdownRules)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.space4),
                    child: Text('${AppTexts.bullet}$r', style: AppStyles.helpBody(context)),
                  ),
                const SizedBox(height: AppSizes.space16),

                Text(ProfileTexts.helpTemplate, style: AppStyles.helpHeading(context)),
                const SizedBox(height: AppSizes.space6),
                Text(ProfileTexts.helpTemplateNote, style: AppStyles.helpBody(context)),
                const SizedBox(height: AppSizes.space4),
                Text(ProfileTexts.helpMarkdownTemplate, style: AppStyles.helpBody(context)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppTexts.close),
          ),
        ],
      );
    },
  );
}
