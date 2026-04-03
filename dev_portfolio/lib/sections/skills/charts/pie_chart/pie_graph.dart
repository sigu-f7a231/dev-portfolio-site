import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../chart_config.dart';
import 'package:flutter/gestures.dart';

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
      width: 300,
      height: 300,
      child: PieChart(
        PieChartData(
          sectionsSpace: ChartLayout.pieSectionsSpace,
          centerSpaceRadius: ChartLayout.pieCenterRadius,
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
          sections: data.entries.mapIndexed((entry, index) {
            final isActive = index == hoveredIndex || index == selectedIndex;
            Color baseColor = ChartColors.mainColors[index % ChartColors.mainColors.length];
            Color highlightColor = HSLColor.fromColor(baseColor)
                .withLightness(0.7)
                .toColor();

            return PieChartSectionData(
              value: entry.value,
              color: isActive ? highlightColor : baseColor,
              radius: isActive ? ChartLayout.pieActiveRadius : ChartLayout.pieRadius,
              borderSide: isActive
                  ? BorderSide(color: ChartColors.highlightBorder, width: ChartLayout.pieActiveBorderWidth)
                  : BorderSide(color: Colors.transparent, width: 0),
              showTitle: false,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// Map.entries に index を付けるヘルパー
extension MapIndex<K, V> on Iterable<MapEntry<K, V>> {
  Iterable<T> mapIndexed<T>(T Function(MapEntry<K, V>, int) f) {
    var i = 0;
    return map((e) => f(e, i++));
  }
}