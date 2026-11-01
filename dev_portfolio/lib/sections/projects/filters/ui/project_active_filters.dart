import 'package:flutter/material.dart';
import '../state/project_filter_state.dart';
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
        // M3 の InputChip（× で外す）
        ...entries.map((e) => InputChip(
              label: Text(e.value),
              onDeleted: () => onRemove(e.key, e.value),
              deleteButtonTooltipMessage: AppTexts.filterRemoveTooltip(e.value),
            )),
        TextButton(
          onPressed: onClearAll,
          child: const Text(AppTexts.filterClearAll),
        ),
      ],
    );
  }
}
