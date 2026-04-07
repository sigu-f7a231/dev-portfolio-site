// lib/sections/projects/views/project_list/project_list_ui.dart
import 'package:flutter/material.dart';
import '../../models/projects_model.dart';
import '../../../config/projects/projects_views_list_config.dart';
import '../../../../utils/string_utils.dart';
import '../project_list/project_list_modal_function.dart'; // モーダル関数

class ProjectListUI extends StatelessWidget {
  final List<Project> projects;
  final bool isDark;

  const ProjectListUI({
    super.key,
    required this.projects,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: projects.length,
      separatorBuilder: (_, __) => ProjectsListConfig.separator,
      itemBuilder: (context, index) {
        final p = projects[index];
        final ongoing = p.period.contains('現在') ||
            p.period.toLowerCase().contains('present');

        return GestureDetector(
          onTap: () => showProjectDetailModal(context, p, isDark: isDark),
          child: Card(
            color: ProjectsListConfig.cardColor(isDark),
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(ProjectsListConfig.cardBorderRadius),
            ),
            child: Padding(
              padding: ProjectsListConfig.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: ProjectsListConfig.titleStyle(isDark),
                  ),
                  ProjectsListConfig.smallSpacing,
                  Text(
                    p.description,
                    style: ProjectsListConfig.subtitleStyle(isDark),
                  ),
                  ProjectsListConfig.smallSpacing,
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: ProjectsListConfig.scheduleIconSize,
                        color: ProjectsListConfig.periodTextColor(isDark),
                      ),
                      SizedBox(width: ProjectsListConfig.periodIconSpacing),
                      Text(
                        p.period,
                        style: ProjectsListConfig.subtitleStyle(isDark).copyWith(
                          fontSize: ProjectsListConfig.periodFontSize,
                          color: ProjectsListConfig.periodTextColor(isDark),
                        ),
                      ),
                    ],
                  ),
                  if (ongoing)
                    Container(
                      margin: ProjectsListConfig.ongoingTagMargin,
                      padding: ProjectsListConfig.ongoingTagPadding,
                      decoration: BoxDecoration(
                        color: ProjectsListConfig.ongoingTagColor,
                        borderRadius: BorderRadius.circular(
                            ProjectsListConfig.ongoingTagBorderRadius),
                      ),
                      child: Text(
                        "進行中",
                        style: TextStyle(
                          fontSize: ProjectsListConfig.ongoingTagFontSize,
                          color: ProjectsListConfig.ongoingTagTextColor,
                        ),
                      ),
                    ),
                  ProjectsListConfig.smallSpacing,
                  // 🔹 スキル一覧表示
                  if (p.skills.isNotEmpty)
                    Wrap(
                      spacing: ProjectsListConfig.skillButtonSpacing,
                      runSpacing: ProjectsListConfig.skillButtonRunSpacing,
                      children: splitSkills(p.skills).map((skill) {
                        return Container(
                          padding: ProjectsListConfig.skillButtonPadding,
                          decoration: BoxDecoration(
                            color: ProjectsListConfig.skillButtonColor(isDark),
                            borderRadius: BorderRadius.circular(
                                ProjectsListConfig.skillButtonBorderRadius),
                          ),
                          child: Text(
                            skill,
                            style: TextStyle(
                              color:
                                  ProjectsListConfig.skillButtonTextColor(isDark),
                              fontSize: ProjectsListConfig.skillButtonFontSize,
                              fontWeight:
                                  ProjectsListConfig.skillButtonFontWeight,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ProjectsListConfig.smallSpacing,
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                      ),
                      onPressed: () =>
                          showProjectDetailModal(context, p, isDark: isDark),
                      child: Text('詳細を見る'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}