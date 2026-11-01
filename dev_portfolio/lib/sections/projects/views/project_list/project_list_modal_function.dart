import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/projects_model.dart';
import '../../project_modal_format.dart';
import '../../../config/projects/projects_views_list_config.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_styles.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';
import '../../../../widgets/settled_reveal.dart';
import 'project_workflow_steps.dart';
import 'project_detail_sections.dart';

void showProjectDetailModal(
  BuildContext context,
  Project project, {
  bool showWorkflow = false, // ← 追加
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        insetPadding: ProjectsListConfig.modalPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: ProjectsListConfig.modalMaxHeight),
          // 開いたら、中身の描画が落ち着くまで Progress indicator を出し、落ち着いたら表示する
          child: SettledReveal(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== 固定ヘッダー：プロジェクト名＋×（スクロールしても常に見える） =====
                Padding(
                  padding: ProjectsListConfig.modalHeaderPadding,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSizes.space8),
                          child: Text(
                            project.title,
                            style: AppStyles.title(
                              context,
                              fontSize: ProjectsListConfig.modalTitleFontSize,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: context.colors.modalClose,
                          size: ProjectsListConfig.closeButtonSize,
                        ),
                        tooltip: AppTexts.close,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ===== 本文：ここだけスクロールする =====
                Flexible(
                  child: SingleChildScrollView(
                    padding: ProjectsListConfig.modalBodyPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ..._buildDetailSections(project, showWorkflow: showWorkflow),
                        // Workflow：工程を横に並べたステップ表示（Work のみ）
                        if (showWorkflow && project.workflow.isNotEmpty)
                          ProjectWorkflowSteps(project: project),
                      ],
                    ),
                  ),
                ),

                // ===== 固定フッター：公開ページ（リンクがあるときだけ） =====
                if (project.link.isNotEmpty) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: ProjectsListConfig.modalFooterPadding,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: () async {
                          final uri = Uri.tryParse(project.link);
                          if (uri != null && await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        style: AppStyles.linkButton(context),
                        child: const Text(AppTexts.openPublicPage),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// 本文の各項目（プロジェクト名と Workflow は別に表示するので除く）
/// - 説明・詳細：文章のまま／期間：開始 → 終了・長さ
/// - それ以外（使用技術など）：カンマ区切りの値を 1 つずつ枠に入れて並べる
/// - 中身が空、または「利用なし」だけの項目は出さない
List<Widget> _buildDetailSections(Project project, {required bool showWorkflow}) {
  const textFields = {
    AppTexts.fieldDescription,
    AppTexts.fieldDetails,
  };
  const skipFields = {AppTexts.fieldTitle, AppTexts.fieldWorkflow};

  final sections = <Widget>[];
  for (final field in ProjectModalFormat.fields(showWorkflow: showWorkflow)) {
    if (skipFields.contains(field.label)) continue;
    final raw = field.valueGetter(project).trim();

    if (field.label == AppTexts.fieldPeriod) {
      if (raw.isEmpty) continue;
      sections.add(ProjectDetailSection(label: field.label, child: ProjectDetailPeriod(project: project)));
      continue;
    }

    if (textFields.contains(field.label)) {
      if (raw.isEmpty) continue;
      sections.add(ProjectDetailSection(label: field.label, child: ProjectDetailText(text: raw)));
      continue;
    }

    final values = raw
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty && v != Project.notUsed)
        .toList();
    if (values.isEmpty) continue;
    sections.add(ProjectDetailSection(label: field.label, child: ProjectDetailChips(values: values)));
  }
  return sections;
}
