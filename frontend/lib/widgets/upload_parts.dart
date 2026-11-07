// lib/widgets/upload_parts.dart
//
// アップロード画面（Work / Private / プロフィール）で共通に使う部品
// - UploadSteps        … 番号付きの手順
// - SelectedFileStatus … 選んだファイルの状態（未選択 / 読み込める / 読み込めない＋理由）
// - confirmUpload      … アップロード前の確認画面（OK のときだけ true）
// - runReloading       … アップロード後の全画面ローディング（起動時と同じ M3 の Circular progress indicator）
// - UploadSourcePanel  … ［テンプレートを保存］［テンプレートをコピー］／［ファイルを選択］［テキストを貼り付け］
// - copyTemplateText   … テンプレートの中身をクリップボードにコピー（ファイルを保存できない人向け）
// - showPasteYamlDialog … YAML / Markdown のテキストを貼り付ける画面（ファイルを選べない人向け。クリアボタン付き）
// - saveTemplateFile   … テンプレート（YAML / Markdown）を名前を付けて保存
// - confirmOverwrite   … 今の Work / Private と違いがあるとき、上書きしてよいかを確かめる
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import 'app_loading_indicator.dart';
import 'app_segment.dart';
import '../utils/data_format.dart';
import '../utils/file_saver.dart';
import '../utils/projects_diff.dart';
import '../utils/asset_text.dart';

/// 番号付きの手順
class UploadSteps extends StatelessWidget {
  final List<String> steps;

  const UploadSteps({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: AppSizes.profileStepRadius,
                  backgroundColor: colors.navIndicator,
                  child: Text(
                    '${i + 1}',
                    style: AppStyles.countBadgeText(context)
                        .copyWith(color: colors.navSelectedForeground),
                  ),
                ),
                const SizedBox(width: AppSizes.space12),
                Expanded(child: Text(steps[i], style: AppStyles.helpBody(context))),
              ],
            ),
          ),
      ],
    );
  }
}

/// 選んだファイルの状態
class SelectedFileStatus extends StatelessWidget {
  final String? fileName;

  /// 読み込めない理由（空なら読み込める）
  final List<String> errors;

  const SelectedFileStatus({super.key, required this.fileName, this.errors = const []});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ok = fileName != null && errors.isEmpty;

    final (icon, color, label) = fileName == null
        ? (Icons.description_outlined, colors.textTertiary, AppTexts.noFileChosen)
        : ok
            ? (Icons.check_circle, colors.success, AppTexts.fileReady(fileName!))
            : (Icons.error, colors.error, AppTexts.fileRejected(fileName!));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space12),
      decoration: AppStyles.cardPeriod(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppSizes.space20),
              const SizedBox(width: AppSizes.space8),
              Expanded(
                child: Text(label,
                    style: AppStyles.helpBody(context).copyWith(color: color)),
              ),
            ],
          ),
          for (final e in errors)
            Padding(
              padding: const EdgeInsets.only(left: AppSizes.space20 + AppSizes.space8, top: AppSizes.space4),
              child: Text('${AppTexts.bullet}$e', style: AppStyles.dialogError(context)),
            ),
        ],
      ),
    );
  }
}

/// 確認画面の「見出し：値」の 1 行
class ConfirmField extends StatelessWidget {
  final String label;
  final String value;

  const ConfirmField(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.space10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppStyles.filterGroupLabel(context)),
          const SizedBox(height: AppSizes.space2),
          Text(value.trim(), style: AppStyles.helpBody(context)),
        ],
      ),
    );
  }
}

/// アップロード前の確認画面。OK を押したときだけ true
Future<bool> confirmUpload(
  BuildContext context, {
  required String fileName,
  required String replaceTarget, // 例：'Work' / 'プロフィール'
  required Widget summary,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = context.colors;
      return AlertDialog(
        backgroundColor: colors.dialogBackground,
        icon: Icon(Icons.fact_check_outlined, color: colors.primary),
        title: Text(AppTexts.confirmTitle,
            textAlign: TextAlign.center, style: AppStyles.dialogTitle(context)),
        content: SizedBox(
          width: AppSizes.helpDialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppTexts.confirmFile(fileName), style: AppStyles.helpBody(context)),
              const SizedBox(height: AppSizes.space12),
              // 中身（長いときはここだけスクロール）
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: AppSizes.confirmListMaxHeight),
                child: Container(
                  width: double.infinity,
                  decoration: AppStyles.cardPeriod(context),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.space16),
                    child: summary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space12),
              Text(
                AppTexts.confirmReplace(replaceTarget),
                style: AppStyles.helpBody(context).copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppTexts.confirmBack),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppTexts.confirmOk),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

/// アップロード後の全画面ローディング（起動時の表示と同じ見た目）
/// [task]（保存・読み直し）が終わり、最低 AppSizes.reloadMinDuration たって、
/// 描画が落ち着いてから消す。読み込みが終わらなくても reloadMaxDuration で打ち切る。
/// 失敗したら、その理由を返す（成功なら null）。呼び出し側が「保存できませんでした」を出す
Future<Object?> runReloading(NavigatorState navigator, Future<void> Function() task) async {
  Object? error;
  final done = Future<void>(() async {
    final work = () async {
      try {
        await task();
      } catch (e) {
        // 失敗しても画面は戻す（各セクションが空やエラーの表示になる）。ログイン中なら API の誤りの理由など
        error = e;
      }
      for (var i = 0; i < AppSizes.settleFrames; i++) {
        await WidgetsBinding.instance.endOfFrame;
      }
    }();
    await Future.wait([
      work.timeout(AppSizes.reloadMaxDuration, onTimeout: () {}),
      Future<void>.delayed(AppSizes.reloadMinDuration),
    ]);
  });

  final route = DialogRoute<void>(
    context: navigator.context,
    barrierDismissible: false,
    useSafeArea: false,
    builder: (_) => const PopScope(canPop: false, child: _ReloadingScreen()),
  );
  // 閉じるまで待たずに（push の Future は閉じたときに完了する）
  navigator.push(route);
  await done;
  if (route.isActive) navigator.removeRoute(route);
  return error;
}

class _ReloadingScreen extends StatelessWidget {
  const _ReloadingScreen();

  @override
  Widget build(BuildContext context) {
    // 画面全体を背景色で覆い、描き直し中の画面を見せない
    return Material(
      color: context.colors.scaffoldBackground,
      child: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppLoadingIndicator(),
            const SizedBox(height: AppSizes.space16),
            Text(AppTexts.reloading, style: AppStyles.secondary(context)),
          ],
        ),
      ),
    );
  }
}

/// テンプレートとデータの読み込み方法をまとめたボタン群
/// - テンプレート：［テンプレートを保存］［テンプレートをコピー］
/// - データを読み込む：［ファイルを選択］［テキストを貼り付け］
class UploadSourcePanel extends StatelessWidget {
  /// 保存・コピーするテンプレートの形式（YAML / Markdown）
  final DataFormat templateFormat;
  final ValueChanged<DataFormat> onTemplateFormatChanged;
  final VoidCallback onSaveTemplate;
  final VoidCallback onCopyTemplate;
  final VoidCallback? onPickFile; // null のときは押せない（読み込み中）
  final VoidCallback? onPasteText;
  final bool hasSource; // 何か読み込んだ後は「別のファイルを選択」にする

  const UploadSourcePanel({
    super.key,
    this.templateFormat = DataFormat.yaml,
    required this.onTemplateFormatChanged,
    required this.onSaveTemplate,
    required this.onCopyTemplate,
    required this.onPickFile,
    required this.onPasteText,
    required this.hasSource,
  });

  @override
  Widget build(BuildContext context) {
    Widget group(String title, List<Widget> buttons) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppStyles.filterGroupLabel(context)),
            const SizedBox(height: AppSizes.space6),
            Wrap(spacing: AppSizes.space8, runSpacing: AppSizes.space8, children: buttons),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        group(AppTexts.templateGroup, [
          // テンプレートの形式（保存・コピーの両方に効く）
          AppSegment<DataFormat>(
            value: templateFormat,
            onChanged: onTemplateFormatChanged,
            items: const [
              AppSegmentItem(value: DataFormat.yaml, label: AppTexts.formatYaml),
              AppSegmentItem(value: DataFormat.markdown, label: AppTexts.formatMarkdown),
            ],
          ),
          TextButton.icon(
            onPressed: onSaveTemplate,
            icon: const Icon(Icons.save_alt),
            label: const Text(AppTexts.downloadFormat),
          ),
          TextButton.icon(
            onPressed: onCopyTemplate,
            icon: const Icon(Icons.content_copy),
            label: const Text(AppTexts.copyTemplate),
          ),
        ]),
        const SizedBox(height: AppSizes.space12),
        group(AppTexts.inputGroup, [
          OutlinedButton.icon(
            onPressed: onPickFile,
            icon: const Icon(Icons.attach_file),
            label: Text(hasSource ? AppTexts.chooseAnotherFile : AppTexts.chooseFile),
          ),
          OutlinedButton.icon(
            onPressed: onPasteText,
            icon: const Icon(Icons.content_paste),
            label: const Text(AppTexts.pasteText),
          ),
        ]),
      ],
    );
  }
}

/// テンプレート（assets 内の YAML / Markdown）を「名前を付けて保存」する
Future<void> saveTemplateFile(
  BuildContext context, {
  required DataKind kind,
  required DataFormat format,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final fileName = templateFileName(kind, format);
  final isMarkdown = format == DataFormat.markdown;
  try {
    final content = await loadAssetText(templateAssetPath(kind, format));
    final result = await FileSaver.saveTextAs(
      fileName: fileName,
      text: content,
      description: isMarkdown ? AppTexts.markdownFileDescription : AppTexts.yamlFileDescription,
      mimeType: isMarkdown ? 'text/markdown' : 'text/yaml',
      extensions: isMarkdown ? const ['.md', '.markdown'] : const ['.yaml', '.yml'],
    );
    if (result == FileSaveResult.saved) {
      messenger.showSnackBar(SnackBar(content: Text(AppTexts.formatSaved(fileName))));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(AppTexts.downloadFailed(e))));
  }
}

/// テンプレート（assets 内の YAML / Markdown）の中身をクリップボードにコピーする
Future<void> copyTemplateText(
  BuildContext context, {
  required String assetPath,
  required String fileName,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final text = await loadAssetText(assetPath);
    await Clipboard.setData(ClipboardData(text: text));
    messenger.showSnackBar(SnackBar(content: Text(AppTexts.templateCopied(fileName))));
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text(AppTexts.copyFailed)));
  }
}

/// YAML のテキストを貼り付ける画面。「読み込む」で入力したテキストを返す（キャンセルは null）
/// 形式の確認は呼び出し側で行う（ファイルを選んだときと同じ流れ）
Future<String?> showPasteYamlDialog(BuildContext context, {String initialText = ''}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PasteYamlDialog(initialText: initialText),
  );
}

class _PasteYamlDialog extends StatefulWidget {
  final String initialText;

  const _PasteYamlDialog({required this.initialText});

  @override
  State<_PasteYamlDialog> createState() => _PasteYamlDialogState();
}

class _PasteYamlDialogState extends State<_PasteYamlDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialText);
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// クリップボードの中身を入力欄に入れる（ブラウザが許可しないときは手で貼り付けてもらう）
  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text ?? '';
      setState(() {
        if (text.trim().isEmpty) {
          _message = AppTexts.clipboardEmpty;
        } else {
          _controller.text = text;
          _message = null;
        }
      });
    } catch (_) {
      setState(() => _message = AppTexts.clipboardDenied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.dialogBackground,
      insetPadding: const EdgeInsets.all(AppSizes.space16),
      icon: Icon(Icons.content_paste, color: colors.primary),
      title: Text(AppTexts.pasteTitle,
          textAlign: TextAlign.center, style: AppStyles.dialogTitle(context)),
      content: SizedBox(
        width: AppSizes.helpDialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppTexts.pasteLead, style: AppStyles.helpBody(context)),
              const SizedBox(height: AppSizes.space12),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: AppSizes.pasteMinLines,
                  maxLines: AppSizes.pasteMaxLines,
                  keyboardType: TextInputType.multiline,
                  // YAML はインデントが大事なので、自動の書き換えをしない
                  autocorrect: false,
                  enableSuggestions: false,
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  style: AppStyles.codeText(context),
                  decoration: InputDecoration(
                    hintText: AppTexts.pasteHint,
                    hintMaxLines: AppSizes.pasteMinLines,
                    border: const OutlineInputBorder(),
                    errorText: _message,
                    // 入力欄の右上の × でも空にできる
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: AppTexts.pasteClear,
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _controller.clear();
                              _message = null;
                            }),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space8),
              Wrap(
                spacing: AppSizes.space8,
                runSpacing: AppSizes.space4,
                children: [
                  TextButton.icon(
                    onPressed: _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_go),
                    label: const Text(AppTexts.pasteFromClipboard),
                  ),
                  // 入力欄を空にする（空のときは押せない）
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) => TextButton.icon(
                      onPressed: value.text.isEmpty
                          ? null
                          : () => setState(() {
                                _controller.clear();
                                _message = null;
                              }),
                      icon: const Icon(Icons.clear_all),
                      label: const Text(AppTexts.pasteClear),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppTexts.cancel),
        ),
        // 空のときは押せない
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) => FilledButton(
            onPressed: value.text.trim().isEmpty
                ? null
                : () => Navigator.of(context).pop(_controller.text),
            child: const Text(AppTexts.pasteApply),
          ),
        ),
      ],
    );
  }
}

/// 今の Work / Private と、これからアップロードする内容に違いがあるときに、上書きしてよいかを確かめる
/// - [diffs]：（表示名, 違い）。違いのないものは出さない
/// - 違いが 1 つもなければ確かめずに true
/// - 「上書きしてアップロード」を選んだときだけ true（やめる・外側のタップは false）
Future<bool> confirmOverwrite(
  BuildContext context, {
  required List<(String, ProjectsDiff)> diffs,
}) async {
  final changed = diffs.where((d) => d.$2.hasChanges).toList();
  if (changed.isEmpty) return true;

  final ok = await showDialog<bool>(
    context: context,
    builder: (context) {
      final colors = context.colors;

      Widget titles(String heading, List<String> items, IconData icon, Color color) {
        if (items.isEmpty) return const SizedBox.shrink();
        final shown = items.take(AppSizes.overwriteMaxTitles).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.space10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: AppSizes.space20, color: color),
                  const SizedBox(width: AppSizes.space6),
                  Expanded(child: Text(heading, style: AppStyles.filterGroupLabel(context))),
                ],
              ),
              for (final t in shown)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.space24 + AppSizes.space2, top: AppSizes.space2),
                  child: Text('${AppTexts.bullet}$t', style: AppStyles.helpBody(context)),
                ),
              if (items.length > shown.length)
                Padding(
                  padding: const EdgeInsets.only(left: AppSizes.space24 + AppSizes.space2, top: AppSizes.space2),
                  child: Text(OverwriteTexts.more(items.length - shown.length),
                      style: AppStyles.helpBody(context).copyWith(color: colors.textTertiary)),
                ),
            ],
          ),
        );
      }

      return AlertDialog(
        backgroundColor: colors.dialogBackground,
        icon: Icon(Icons.warning_amber_rounded, color: colors.error),
        title: Text(OverwriteTexts.title,
            textAlign: TextAlign.center, style: AppStyles.dialogTitle(context)),
        content: SizedBox(
          width: AppSizes.helpDialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                OverwriteTexts.lead(changed.map((d) => d.$1).join('・')),
                style: AppStyles.helpBody(context),
              ),
              const SizedBox(height: AppSizes.space12),
              // 違いの一覧（長いときはここだけスクロール）
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: AppSizes.confirmListMaxHeight),
                child: Container(
                  width: double.infinity,
                  decoration: AppStyles.cardPeriod(context),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSizes.space16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (label, diff) in changed) ...[
                          if (changed.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSizes.space8),
                              child: Text(label, style: AppStyles.helpHeading(context)),
                            ),
                          titles(OverwriteTexts.removed(diff.removed.length), diff.removed,
                              Icons.remove_circle_outline, colors.error),
                          titles(OverwriteTexts.changed(diff.changed.length), diff.changed,
                              Icons.edit_outlined, colors.primary),
                          titles(OverwriteTexts.added(diff.added.length), diff.added,
                              Icons.add_circle_outline, colors.success),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.space12),
              Text(OverwriteTexts.question, style: AppStyles.helpEmphasis(context)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(OverwriteTexts.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.scheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(OverwriteTexts.overwrite),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

