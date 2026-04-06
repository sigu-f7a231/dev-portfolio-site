import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../config/skills_chart_config.dart';
import 'package:flutter/gestures.dart';
import '../../../../utils/graph_utils.dart';

class PieGraph extends StatelessWidget {
  final Map<String, double> data;
  final bool isDark;
  final int? hoveredIndex;
  final int? selectedIndex;
  final Function(int?) onHover;
  final Function(int?) onSelect;

  const PieGraph({
    super.key,
    required this.data,
    required this.isDark,
    this.hoveredIndex,
    this.selectedIndex,
    required this.onHover,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ChartLayout.pieSize,
      height: ChartLayout.pieSize,
      child: PieChart(
        PieChartData(
          sectionsSpace: ChartLayout.pieSectionsSpace,
          centerSpaceRadius: ChartLayout.pieCenterRadius,
          pieTouchData: PieTouchData(
            touchCallback: (event, pieTouchResponse) {
              final idx = pieTouchResponse?.touchedSection?.touchedSectionIndex;

              if (event is PointerDownEvent) {
                onSelect(idx);
              } else if (event is! PointerExitEvent &&
                  event is! PointerUpEvent) {
                onHover(idx);
              } else {
                onHover(null);
              }
            },
          ),
          sections: data.entries.mapIndexed((entry, index) {
            final isActive =
                index == hoveredIndex || index == selectedIndex;

            final baseColor = ChartColors.mainColors[
                index % ChartColors.mainColors.length];

            return PieChartSectionData(
              value: entry.value,
              color: ChartColors.pieColor(baseColor, isActive),
              radius: isActive
                  ? ChartLayout.pieActiveRadius
                  : ChartLayout.pieRadius,
              borderSide: ChartColors.pieBorder(isActive),
              showTitle: false,
            );
          }).toList(),
        ),
      ),
    );
  }
}