import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/skills_pie_chart_config.dart';
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

            final baseColor = PieChartColors.mainColors[
                index % PieChartColors.mainColors.length];

            return PieChartSectionData(
              value: entry.value,
              color: PieChartColors.pieColor(baseColor, isActive),
              radius: isActive
                  ? PieChartLayout.pieActiveRadius
                  : PieChartLayout.pieRadius,
              borderSide: PieChartColors.pieBorder(isActive),
              showTitle: false,
            );
          }).toList(),
        ),
      ),
    );
  }
}