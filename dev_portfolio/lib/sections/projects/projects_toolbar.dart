// lib/sections/projects/projects_toolbar.dart
import 'package:flutter/material.dart';
import 'projects_view_switch.dart';
import '../../widgets/app_segment.dart';
import '../config/projects/projects_section_config.dart';
import '../../theme/app_styles.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';

/// Work/Private ・ フィルター ・ List/Collection を 1 行にまとめたツールバー
/// （狭い画面では折り返す）
class ProjectsToolbar extends StatelessWidget {
  final bool isWork;
  final int? workCount;
  final int? privateCount;
  final ValueChanged<bool> onTabChanged;

  final bool filterOpen;
  final int activeFilterCount;
  final VoidCallback onFilterPressed;

  final bool showCollection;
  final ValueChanged<bool> onViewChanged;

  const ProjectsToolbar({
    super.key,
    required this.isWork,
    required this.workCount,
    required this.privateCount,
    required this.onTabChanged,
    required this.filterOpen,
    required this.activeFilterCount,
    required this.onFilterPressed,
    required this.showCollection,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSizes.space12,
      runSpacing: AppSizes.space12,
      children: [
        AppSegment<bool>(
          value: isWork,
          onChanged: onTabChanged,
          items: [
            AppSegmentItem(value: true, label: AppTexts.work, count: workCount),
            AppSegmentItem(value: false, label: AppTexts.private, count: privateCount),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onFilterPressed,
              style: AppStyles.toolbarButton(context, active: filterOpen),
              // 適用中の条件数は M3 の Badge でアイコンに重ねる
              icon: Badge.count(
                count: activeFilterCount,
                isLabelVisible: activeFilterCount > 0,
                child: const Icon(Icons.tune, size: ProjectsSectionConfig.filterIconSize),
              ),
              label: const Text(AppTexts.filter),
            ),
            const SizedBox(width: AppSizes.space12),
            ProjectsViewSwitch(
              showCollection: showCollection,
              onToggle: onViewChanged,
            ),
          ],
        ),
      ],
    );
  }
}
