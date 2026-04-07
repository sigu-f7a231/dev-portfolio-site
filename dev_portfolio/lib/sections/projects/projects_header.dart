import 'package:flutter/material.dart';
import 'projects_view_switch.dart';
import '../config/projects/projects_header_config.dart';

/// Projects セクションのヘッダー
/// タイトル + List/Collection 切替スイッチ（左側に配置）
class ProjectsHeader extends StatelessWidget {
  final ValueNotifier<bool> showCollectionNotifier;
  final bool isDark;

  const ProjectsHeader({
    super.key,
    required this.showCollectionNotifier,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ProjectsWidgetsHeaderConfig.titlePadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start, // 左揃え
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // セクションタイトル
          Text(
            'Projects',
            style: ProjectsWidgetsHeaderConfig.titleStyle(isDark),
          ),

          const SizedBox(width: 12), // タイトルとスイッチの間隔

          // List / Collection スイッチ
          ValueListenableBuilder<bool>(
            valueListenable: showCollectionNotifier,
            builder: (context, showCollection, _) {
              return ProjectsViewSwitch(
                showCollection: showCollection,
                isDark: isDark,
                onToggle: (val) {
                  showCollectionNotifier.value = val;
                },
                reverseOrder: true, // 左右反転
              );
            },
          ),
        ],
      ),
    );
  }
}