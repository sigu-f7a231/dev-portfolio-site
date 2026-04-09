import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/skills/skills_pie_chart_config.dart';
import 'package:flutter/gestures.dart';
import '../../../../utils/graph_utils.dart';

class PieGraph extends StatelessWidget {
  final Map<String, double> data;
  final bool isDark;
  final int? hoveredIndex;
  final int? selectedIndex;
  final Function(int?) onHover;
  final Function(int?) onSelect;
  final int topN;

  const PieGraph({
    super.key,
    required this.data,
    required this.isDark,
    this.hoveredIndex,
    this.selectedIndex,
    required this.onHover,
    required this.onSelect,
    this.topN = 10,
  });

  @override
  Widget build(BuildContext context) {
    // データを値順にソート
    final sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 上位N件とその他
    final topEntries = sortedEntries.take(topN).toList();
    final otherEntries = sortedEntries.skip(topN).toList();
    if (otherEntries.isNotEmpty) {
      final otherValue =
          otherEntries.fold<double>(0, (sum, e) => sum + e.value);
      topEntries.add(MapEntry('その他', otherValue));
    }

    return SizedBox(
      width: PieChartLayout.pieSize,
      height: PieChartLayout.pieSize,
      child: PieChart(
        PieChartData(
          sectionsSpace: PieChartLayout.pieSectionsSpace,
          centerSpaceRadius: PieChartLayout.pieCenterRadius,
          pieTouchData: PieTouchData(
            touchCallback: (event, pieTouchResponse) {
              final idx = pieTouchResponse?.touchedSection?.touchedSectionIndex;
              if (event is PointerDownEvent) {
                onSelect(idx);
              } else if (event is! PointerExitEvent && event is! PointerUpEvent) {
                onHover(idx);
              } else {
                onHover(null);
              }
            },
          ),
          sections: topEntries.mapIndexed((entry, index) {
            final isHovered = index == hoveredIndex;
            final isSelected = index == selectedIndex;
            final baseColor =
                PieChartColors.mainColors[index % PieChartColors.mainColors.length];

            Color sectionColor = PieChartColors.pieColor(
              baseColor,
              isDark: isDark,
              isHovered: isHovered,
              isSelected: isSelected,
            );

            if (isSelected) {
              sectionColor = HSLColor.fromColor(baseColor)
                  .withLightness(PieChartLayout.pieHighlightLightness)
                  .toColor();
            }

            return PieChartSectionData(
              value: entry.value,
              color: sectionColor,
              radius: isSelected
                  ? PieChartLayout.pieActiveRadius
                  : PieChartLayout.pieRadius,
              borderSide: isSelected
                  ? BorderSide(
                      color: PieChartColors.highlightBorder,
                      width: PieChartLayout.pieActiveBorderWidth,
                    )
                  : BorderSide(
                      color: Colors.transparent,
                      width: PieChartLayout.pieInactiveBorderWidth,
                    ),
              showTitle: false,
            );
          }).toList(),
        ),
      ),
    );
  }
}