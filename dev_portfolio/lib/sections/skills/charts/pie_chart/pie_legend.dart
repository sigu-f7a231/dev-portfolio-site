import 'package:flutter/material.dart';
import '../../../config/skills/skills_pie_chart_config.dart';
import '../../../../utils/graph_utils.dart';
import '../../../../theme/app_theme.dart';
import '../../../../theme/app_styles.dart';
import '../../../../constants/app_sizes.dart';
import '../../../../constants/app_texts.dart';

class PieLegend extends StatelessWidget {
  final Map<String, double> data;
  final int topN;
  final int? hoveredIndex;
  final int? selectedIndex;
  final Function(int) onHover;
  final Function(int) onSelect;

  const PieLegend({
    super.key,
    required this.data,
    required this.onHover,
    required this.onSelect,
    this.topN = AppSizes.chartTopN,
    this.hoveredIndex,
    this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // データを値順にソート
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 上位N件 + その他
    final topEntries = sortedEntries.take(topN).toList();
    final otherEntries = sortedEntries.skip(topN).toList();
    if (otherEntries.isNotEmpty) {
      final otherValue = otherEntries.fold<double>(0, (sum, e) => sum + e.value);
      topEntries.add(MapEntry(AppTexts.chartOthers, otherValue));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topEntries.mapIndexed((entry, index) {
        final isActive = index == hoveredIndex || index == selectedIndex;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => onHover(index),
          onExit: (_) => onHover(-1),
          child: GestureDetector(
            onTap: () => onSelect(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: PieChartLayout.pieLegendItemSpacing),
              child: Row(
                children: [
                  Container(
                    width: PieChartLayout.pieLegendColorSize,
                    height: PieChartLayout.pieLegendColorSize,
                    decoration: BoxDecoration(
                      color: colors.seriesColor(index),
                      borderRadius: BorderRadius.circular(
                          PieChartLayout.pieLegendColorRadius),
                      border: isActive
                          ? Border.all(
                              color: colors.chartHighlight,
                              width: PieChartLayout.pieActiveBorderWidth,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: PieChartLayout.pieLegendSpacingItem),
                  Expanded(
                    child: Text(
                      entry.key,
                      style: AppStyles.chartLabel(context, isActive: isActive),
                    ),
                  ),
                  SizedBox(
                    width: PieChartLayout.pieLegendValueWidth,
                    child: Text(
                      '${entry.value.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: AppStyles.chartValue(context, isActive: isActive),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}