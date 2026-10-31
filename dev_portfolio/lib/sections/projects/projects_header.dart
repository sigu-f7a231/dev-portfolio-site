import 'package:flutter/material.dart';
import '../config/projects/projects_header_config.dart';
import '../../theme/app_styles.dart';
import '../../constants/app_texts.dart';

/// Projects セクションのタイトル
/// （List / Collection の切替はツールバー projects_toolbar.dart に移動）
class ProjectsHeader extends StatelessWidget {
  const ProjectsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ProjectsWidgetsHeaderConfig.titlePadding,
      child: Text(
        AppTexts.navProjects,
        style: AppStyles.title(
          context,
          fontSize: ProjectsWidgetsHeaderConfig.titleFontSize,
        ),
      ),
    );
  }
}
