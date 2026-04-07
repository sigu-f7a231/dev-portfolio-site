import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/projects_model.dart';
import '../../project_modal_format.dart';
import '../../../config/projects/projects_views_list_config.dart';

void showProjectDetailModal(BuildContext context, Project project, {bool isDark = false}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        insetPadding: ProjectsListConfig.modalPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: ProjectsListConfig.modalMaxHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: ProjectsListConfig.modalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // バツボタン
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        color: ProjectsListConfig.closeButtonColor,
                        size: ProjectsListConfig.closeButtonSize,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  // プロジェクト詳細フィールド
                  ...ProjectModalFormat.fields.map((field) {
                    final value = field.valueGetter(project);
                    return Padding(
                      padding: ProjectsListConfig.fieldPadding,
                      child: RichText(
                        text: TextSpan(
                          text: '${field.label}: ',
                          style: ProjectsListConfig.fieldLabelStyleDark(
                              field.fontSize, isDark),
                          children: [
                            TextSpan(
                              text: value,
                              style: ProjectsListConfig.fieldValueStyleDark(
                                  field.isBold, isDark),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  ProjectsListConfig.verticalSpacingSmall,
                  // 公開ページリンク
                  if (project.link.isNotEmpty)
                    ElevatedButton(
                      onPressed: () async {
                        final uri = Uri.tryParse(project.link);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      style: ProjectsListConfig.linkButtonStyle,
                      child: const Text("公開ページを見る"),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}