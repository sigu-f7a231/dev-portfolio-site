// lib/widgets/profile_setup_dialog.dart
//
// 「あなたのことを教えてください」：プロフィール YAML の入力画面
// - YAML を指定せずに起動したときだけ出す（HomePage から呼ぶ）
// - できること：テンプレートを名前を付けて保存・コピー ／ ファイルを選択・テキストを貼り付け（その場で形式を確認）／
//   アップロード（確認画面で中身を見て OK のときだけ。反映中は全画面ローディング）／ ⓘ で書き方の説明（説明だけ）
// - 正しい YAML を読み込むまで閉じられない（外側のタップ・Esc・戻るでも閉じない）
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/profile.dart';
import '../utils/profile_store.dart';
import '../utils/file_saver.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import 'upload_parts.dart';

const String _templateAsset = 'assets/data/format_profile.yaml';

/// 入力画面を出す（読み込みが終わると閉じる）
Future<void> showProfileSetupDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // 外側をタップしても閉じない
    builder: (_) => const PopScope(
      canPop: false, // Esc・ブラウザの戻るでも閉じない
      child: _ProfileSetupDialog(),
    ),
  );
}

/// テンプレートを「名前を付けて保存」
Future<void> _saveTemplate(BuildContext context) async {
  try {
    final content = await rootBundle.loadString(_templateAsset);
    final result = await FileSaver.saveTextAs(
      fileName: ProfileTexts.templateFileName,
      text: content,
      description: AppTexts.yamlFileDescription,
      mimeType: 'text/yaml',
      extensions: const ['.yaml', '.yml'],
    );
    if (result == FileSaveResult.saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.formatSaved(ProfileTexts.templateFileName))),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.downloadFailed(e))),
      );
    }
  }
}

class _ProfileSetupDialog extends StatefulWidget {
  const _ProfileSetupDialog();

  @override
  State<_ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends State<_ProfileSetupDialog> {
  bool _picking = false;
  String? _fileName;
  String? _text; // 形式が正しいときだけ入る
  Profile? _profile;
  List<String> _errors = const [];

  /// 前に貼り付けたテキスト（もう一度開いたときに続きから直せるように）
  String _pasted = '';

  /// 1. ファイルを選ぶ → その場で形式を確かめる（間違っていればアップロードできない）
  Future<void> _pick() async {
    setState(() => _picking = true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['yaml', 'yml'], // .yaml / .yml 以外は選べない
        withData: true,
      );
      final file = picked?.files.single;
      if (file == null || file.bytes == null) return; // キャンセル（前の選択はそのまま）

      final name = file.name.toLowerCase();
      if (!name.endsWith('.yaml') && !name.endsWith('.yml')) {
        setState(() {
          _fileName = file.name;
          _text = null;
          _profile = null;
          _errors = [ProfileTexts.extensionOnly];
        });
        return;
      }

      _apply(utf8.decode(file.bytes!), file.name);
    } catch (e) {
      setState(() {
        _text = null;
        _profile = null;
        _errors = [AppTexts.fileReadFailed(e)];
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// 読み込んだテキスト（ファイル・貼り付け共通）の形式を確かめて、状態に反映する
  void _apply(String text, String sourceName) {
    final result = Profile.parse(text);
    setState(() {
      _fileName = sourceName;
      _text = result.isOk ? text : null;
      _profile = result.profile;
      _pasted = sourceName == AppTexts.pastedTextName ? text : _pasted;
      _errors = result.errors;
    });
  }

  /// 1'. テキストを貼り付ける（ファイルを選べない人向け）→ ファイルと同じく形式を確かめる
  Future<void> _paste() async {
    final text = await showPasteYamlDialog(context, initialText: _pasted);
    if (text == null || !mounted) return; // キャンセル
    _apply(text, AppTexts.pastedTextName);
  }

  /// 2. 確認画面 → OK なら 3. 全画面ローディングを出して反映
  Future<void> _upload() async {
    final text = _text, profile = _profile;
    if (text == null || profile == null) return;

    final ok = await confirmUpload(
      context,
      fileName: _fileName!,
      replaceTarget: ProfileTexts.replaceTarget,
      summary: _ProfileSummary(profile: profile),
    );
    if (!ok || !mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop(); // 入力画面を閉じる（PopScope は戻る操作だけを止めるので、ここでは閉じられる）

    await runReloading(navigator, () async {
      ProfileStore.instance.setUploaded(text, profile);
    });

    messenger.showSnackBar(const SnackBar(content: Text(ProfileTexts.uploaded)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final startupErrors = ProfileStore.instance.startupErrors;

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
              const UploadSteps(steps: ProfileTexts.setupSteps),
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

              UploadSourcePanel(
                onSaveTemplate: () => _saveTemplate(context),
                onCopyTemplate: () => copyTemplateText(
                  context,
                  assetPath: _templateAsset,
                  fileName: ProfileTexts.templateFileName,
                ),
                onPickFile: _picking ? null : _pick,
                onPasteText: _picking ? null : _paste,
                hasSource: _fileName != null,
              ),
              const SizedBox(height: AppSizes.space12),
              SelectedFileStatus(fileName: _fileName, errors: _errors),
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
          onPressed: _text == null || _picking ? null : _upload,
          icon: const Icon(Icons.upload_file),
          label: const Text(AppTexts.upload),
        ),
      ],
    );
  }
}

/// 確認画面の中身：プロフィールの各項目
class _ProfileSummary extends StatelessWidget {
  final Profile profile;

  const _ProfileSummary({required this.profile});

  @override
  Widget build(BuildContext context) {
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

                Text(ProfileTexts.helpTemplate, style: AppStyles.helpHeading(context)),
                const SizedBox(height: AppSizes.space6),
                Text(ProfileTexts.helpTemplateNote, style: AppStyles.helpBody(context)),
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
