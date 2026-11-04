// lib/sections/header/yaml_upload_dialog.dart
//
// Work / Private 用 YAML のアップロード画面（DesktopHeader / MobileHeader で共通）
// 見た目と流れは起動時のプロフィール入力画面（widgets/profile_setup_dialog.dart）と同じ：
//   見出し＋ⓘ ／ 説明 ／ 番号付きの手順 ／
//   テンプレート［保存］［コピー］・データを読み込む［ファイルを選択］［テキストを貼り付け］／ 読み込んだものの状態
//   ［キャンセル］［アップロード］
// 1. 「ファイルを選択」か「テキストを貼り付け」で読み込むと、その場で形式を確かめる
//    （間違っていれば理由を出し、アップロードできない。ファイルを保存・選択できない人は貼り付けで使える）
// 2. 「アップロード」→ 確認画面で中身（プロジェクトの一覧）を見て、OK のときだけ反映
// 3. 反映中は起動時と同じ全画面ローディング（最低 5 秒）を出してから画面に戻す
// - テンプレートの保存はこの画面だけ（ⓘ の説明画面には置かない）
// - こちらは任意なので、キャンセルで閉じられる
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'yaml_format_help.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_styles.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';
import '../../utils/work_yaml_loader.dart';
import '../../utils/private_yaml_loader.dart';
import '../../widgets/upload_parts.dart';
import '../../utils/projects_yaml_validator.dart';
import '../../utils/browser/browser.dart';

/// アップロード画面を開く。保存できたら [onSaved]（Skills / Projects の読み直し）を呼ぶ
Future<void> showYamlUploadDialog(
  BuildContext context, {
  required String dataType, // 'work' or 'private'
  VoidCallback? onSaved,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _YamlUploadDialog(dataType: dataType, onSaved: onSaved),
  );
}

class _YamlUploadDialog extends StatefulWidget {
  final String dataType;
  final VoidCallback? onSaved;

  const _YamlUploadDialog({required this.dataType, this.onSaved});

  @override
  State<_YamlUploadDialog> createState() => _YamlUploadDialogState();
}

class _YamlUploadDialogState extends State<_YamlUploadDialog> {
  bool _picking = false;
  String? _fileName;
  String? _text; // 形式が正しいときだけ入る
  List<String> _errors = const [];

  /// 前に貼り付けたテキスト（もう一度「テキストを貼り付け」を開いたときに続きから直せるように）
  String _pasted = '';

  bool get _isWork => widget.dataType == 'work';
  String get _label => _isWork ? AppTexts.work : AppTexts.private;

  /// 1. ファイルを選ぶ → その場で形式を確かめる
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

      _apply(utf8.decode(file.bytes!), file.name);
    } catch (e) {
      setState(() {
        _text = null;
        _errors = [AppTexts.fileReadFailed(e)];
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  /// 読み込んだテキスト（ファイル・貼り付け共通）の形式を確かめて、状態に反映する
  void _apply(String text, String sourceName) {
    final ok = isValidProjectsYaml(text, widget.dataType);
    setState(() {
      _fileName = sourceName;
      _text = ok ? text : null;
      _pasted = sourceName == AppTexts.pastedTextName ? text : _pasted;
      _errors = ok
          ? const []
          : [AppTexts.formatMismatch(widget.dataType, yamlFormatFileName(widget.dataType))];
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
    final text = _text;
    if (text == null) return;

    final ok = await confirmUpload(
      context,
      fileName: _fileName!,
      replaceTarget: _label,
      summary: _ProjectsSummary(text: text, isWork: _isWork),
    );
    if (!ok || !mounted) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop(); // アップロード画面を閉じる

    await runReloading(navigator, () async {
      // セッションに保存（同じタブなら再読み込みしても残る）→ Skills / Projects を作り直して読み直す
      SessionStore.write(widget.dataType, text);
      widget.onSaved?.call();
      await (_isWork ? WorkYamlLoader.loadYamlString() : PrivateYamlLoader.loadYamlString());
    });

    messenger.showSnackBar(SnackBar(content: Text(AppTexts.uploadSaved(widget.dataType))));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      backgroundColor: colors.dialogBackground,
      icon: Icon(_isWork ? Icons.work_outline : Icons.lock_outline, color: colors.primary),
      title: Row(
        children: [
          // ⓘ と左右のバランスを取るための空き
          const SizedBox(width: AppSizes.profileHelpButtonSize),
          Expanded(
            child: Text(
              _isWork ? AppTexts.workUploadTitle : AppTexts.privateUploadTitle,
              textAlign: TextAlign.center,
              style: AppStyles.dialogTitle(context),
            ),
          ),
          SizedBox(
            width: AppSizes.profileHelpButtonSize,
            child: IconButton(
              icon: Icon(Icons.info_outline, color: colors.textSecondary),
              tooltip: AppTexts.formatHelpTooltip,
              onPressed: () => showYamlFormatHelp(context, widget.dataType),
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
              Text(
                _isWork ? AppTexts.workUploadDescription : AppTexts.privateUploadDescription,
                style: AppStyles.dialogBody(context),
              ),
              const SizedBox(height: AppSizes.space16),
              UploadSteps(
                steps: _isWork ? AppTexts.workUploadSteps : AppTexts.privateUploadSteps,
              ),
              const SizedBox(height: AppSizes.space8),
              UploadSourcePanel(
                onSaveTemplate: () => saveYamlFormat(context, widget.dataType),
                onCopyTemplate: () => copyTemplateText(
                  context,
                  assetPath: 'assets/data/${yamlFormatFileName(widget.dataType)}',
                  fileName: yamlFormatFileName(widget.dataType),
                ),
                onPickFile: _picking ? null : _pick,
                onPasteText: _picking ? null : _paste,
                hasSource: _fileName != null,
              ),
              const SizedBox(height: AppSizes.space12),
              SelectedFileStatus(fileName: _fileName, errors: _errors),
              const SizedBox(height: AppSizes.space12),
              Text(
                _text == null
                    ? AppTexts.uploadNeedsFile
                    : AppTexts.uploadSessionNote(widget.dataType),
                style: AppStyles.helpBody(context).copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ),
      ),
      actionsOverflowButtonSpacing: AppSizes.space8,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppTexts.cancel),
        ),
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

/// 確認画面の中身：プロジェクトの件数と一覧（タイトル・期間・説明）
class _ProjectsSummary extends StatelessWidget {
  final String text;
  final bool isWork;

  const _ProjectsSummary({required this.text, required this.isWork});

  @override
  Widget build(BuildContext context) {
    final projects = (loadYaml(text) as YamlMap)['projects'] as YamlList;

    String period(Object? p) {
      if (p is YamlList) return p.join(' 〜 ');
      return p?.toString() ?? '';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${isWork ? AppTexts.work : AppTexts.private}：${AppTexts.confirmProjectCount(projects.length)}',
          style: AppStyles.helpHeading(context),
        ),
        const SizedBox(height: AppSizes.space8),
        for (var i = 0; i < projects.length; i++) ...[
          if (i > 0) const Divider(height: AppSizes.space16),
          Text('${i + 1}. ${projects[i]['title']}', style: AppStyles.cardTitle(context)),
          if (period(projects[i]['period']).isNotEmpty)
            Text(period(projects[i]['period']), style: AppStyles.cardMeta(context)),
          if ((projects[i]['description'] ?? '').toString().trim().isNotEmpty)
            Text(
              '${projects[i]['description']}'.trim(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.cardDescription(context),
            ),
        ],
      ],
    );
  }
}
