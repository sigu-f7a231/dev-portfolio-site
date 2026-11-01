// lib/sections/header/yaml_format_help.dart
//
// YAML アップロードダイアログ（Work / Private）用の補助 UI
// - フォーマットファイル（assets/data/format_*.yaml）を「名前を付けて保存」するボタン
// - 書き方の説明を開く ⓘ ボタン
// DesktopHeader / MobileHeader の両方から使う。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_styles.dart';
import '../../utils/language_utils.dart';
import '../../constants/app_sizes.dart';
import '../../utils/file_saver.dart';
import '../../constants/app_texts.dart';
import '../../widgets/app_loading_indicator.dart';

/// dataType（'work' / 'private'）に対応するフォーマットファイル名
String yamlFormatFileName(String dataType) =>
    dataType == 'work' ? 'format_work.yaml' : 'format_private.yaml';

/// フォーマットファイルを「名前を付けて保存」する（保存できたらメッセージを出す）
Future<void> saveYamlFormat(BuildContext context, String dataType) async {
  final fileName = yamlFormatFileName(dataType);
  try {
    final content = await rootBundle.loadString('assets/data/$fileName');
    final result = await FileSaver.saveTextAs(
      fileName: fileName,
      text: content,
      description: AppTexts.yamlFileDescription,
      mimeType: 'text/yaml',
      extensions: const ['.yaml', '.yml'],
    );
    if (result == FileSaveResult.saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTexts.formatSaved(fileName))),
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

/// 「フォーマットを保存」ボタン + ⓘ ボタン
class YamlFormatTools extends StatelessWidget {
  final String dataType; // 'work' or 'private'

  const YamlFormatTools({super.key, required this.dataType});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Tooltip(
            message: AppTexts.downloadFormatTooltip(yamlFormatFileName(dataType)),
            child: TextButton.icon(
              onPressed: () => saveYamlFormat(context, dataType),
              icon: const Icon(Icons.save_alt),
              label: const Text(
                AppTexts.downloadFormat,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.info_outline, color: context.colors.textSecondary),
          tooltip: AppTexts.formatHelpTooltip,
          onPressed: () => showYamlFormatHelp(context, dataType),
        ),
      ],
    );
  }
}

/// 書き方の説明ダイアログ
void showYamlFormatHelp(BuildContext context, String dataType) {
  final isWork = dataType == 'work';

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: context.colors.dialogBackground,
        title: Text(
          AppTexts.formatHelpTitle(isWork),
          style: AppStyles.dialogTitle(context),
        ),
        content: SizedBox(
          width: AppSizes.helpDialogWidth,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------- 基本ルール ----------
                Text(AppTexts.helpBasicRules, style: AppStyles.helpHeading(context)),
                const SizedBox(height: AppSizes.space6),
                _bullet(context, AppTexts.helpRuleStructure),
                _bullet(context, AppTexts.helpRuleIndent),
                _bullet(context, AppTexts.helpRuleTitle, emphasis: true),
                if (isWork)
                  _bullet(context, AppTexts.helpRuleWorkflowWork, emphasis: true)
                else
                  _bullet(context, AppTexts.helpRuleWorkflowPrivate, emphasis: true),
                _bullet(context, AppTexts.helpRuleNotUsed),
                const SizedBox(height: AppSizes.space16),

                // ---------- 各項目 ----------
                Text(AppTexts.helpFields, style: AppStyles.helpHeading(context)),
                const SizedBox(height: AppSizes.space6),
                _field(context, 'title', AppTexts.helpTitleFormat, AppTexts.helpTitleNote),
                _field(context, 'description', AppTexts.helpDescriptionFormat,
                    AppTexts.helpDescriptionNote),
                _field(context, 'details', AppTexts.helpDetailsFormat, AppTexts.helpDetailsNote),
                _field(context, 'period', AppTexts.helpPeriodFormat, AppTexts.helpPeriodNote),
                _field(context, 'link', AppTexts.helpLinkFormat, AppTexts.helpLinkNote),
                _field(
                  context,
                  'server_os / db / tools / backend_frameworks / frontend_frameworks / '
                      'ui_frameworks / testing_frameworks / cloud_platforms / aws_services / '
                      'azure_services / gcp_services / container / container_orchestration / '
                      'ai_services / skills',
                  AppTexts.helpListFormat,
                  AppTexts.helpListNote,
                ),
                if (isWork) ...[
                  _field(context, 'workflow', AppTexts.helpWorkflowFormat,
                      AppTexts.helpWorkflowNote),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: AppSizes.space12, bottom: AppSizes.space8),
                    child: Text(
                      LanguageUtils.workflowLabels['ja']!.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join('\n'),
                      style: AppStyles.codeText(context),
                    ),
                  ),
                ],
                const SizedBox(height: AppSizes.space16),

                // ---------- サンプル ----------
                Text(AppTexts.helpSampleTitle(yamlFormatFileName(dataType)),
                    style: AppStyles.helpHeading(context)),
                const SizedBox(height: AppSizes.space6),
                _YamlSample(dataType: dataType),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => saveYamlFormat(context, dataType),
            icon: const Icon(Icons.save_alt),
            label: const Text(AppTexts.save),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppTexts.close),
          ),
        ],
      );
    },
  );
}

Widget _bullet(BuildContext context, String text, {bool emphasis = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.space4),
    child: Text(
      '${AppTexts.bullet}$text',
      style: emphasis ? AppStyles.helpEmphasis(context) : AppStyles.helpBody(context),
    ),
  );
}

Widget _field(BuildContext context, String key, String format, String note) {
  return Padding(
    padding: const EdgeInsets.only(bottom: AppSizes.space8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(key, style: AppStyles.codeText(context).copyWith(fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.only(left: AppSizes.space12),
          child: Text('$format\n$note', style: AppStyles.helpBody(context)),
        ),
      ],
    ),
  );
}

/// assets のフォーマットファイルをそのまま表示する
class _YamlSample extends StatefulWidget {
  final String dataType;

  const _YamlSample({required this.dataType});

  @override
  State<_YamlSample> createState() => _YamlSampleState();
}

class _YamlSampleState extends State<_YamlSample> {
  late final Future<String> _future =
      rootBundle.loadString('assets/data/${yamlFormatFileName(widget.dataType)}');

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space12),
      decoration: AppStyles.codeBlock(context),
      child: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text(AppTexts.helpSampleLoadFailed, style: AppStyles.dialogError(context));
          }
          if (!snapshot.hasData) {
            return const Center(child: AppLoadingIndicator());
          }
          return SelectableText(snapshot.data!, style: AppStyles.codeText(context));
        },
      ),
    );
  }
}
