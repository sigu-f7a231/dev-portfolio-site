import 'package:flutter/material.dart';
import '../state/project_filter_state.dart';
import '../../../config/projects/projects_section_config.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_styles.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';

/// 適用中のフィルター（チップの × で 1 つずつ外せる）
class ProjectActiveFilters extends StatelessWidget {
  final ProjectFilterState filterState;
  final void Function(String key, String value) onRemove;
  final VoidCallback onClearAll;

  const ProjectActiveFilters({
    super.key,
    required this.filterState,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final entries = [
      for (final e in filterState.selectedFilters.entries)
        for (final v in e.value) (key: e.key, value: v),
    ];

    return Wrap(
      spacing: AppSizes.space8,
      runSpacing: AppSizes.space8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(AppTexts.filterActive, style: AppStyles.filterGroupLabel(context)),
        ...entries.map((e) => Container(
              padding: ProjectsSectionConfig.activeFilterPadding,
              decoration: AppStyles.activeFilter(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.value, style: AppStyles.activeFilterText(context)),
                  const SizedBox(width: AppSizes.space4),
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onRemove(e.key, e.value),
                    child: Tooltip(
                      message: AppTexts.filterRemoveTooltip(e.value),
                      child: Icon(
                        Icons.close,
                        size: ProjectsSectionConfig.activeFilterRemoveIconSize,
                        color: context.colors.activeFilterForeground,
                      ),
                    ),
                  ),
                ],
              ),
            )),
        TextButton(
          onPressed: onClearAll,
          child: const Text(AppTexts.filterClearAll),
        ),
      ],
    );
  }
}
