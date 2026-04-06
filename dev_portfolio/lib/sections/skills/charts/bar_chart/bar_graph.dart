// lib/sections/skills/charts/bar_chart/bar_graph.dart
import 'package:flutter/material.dart';
import '../../../config/skills_chart_config.dart';

class BarGraph extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final int? touchedIndex;
  final bool isDark;
  final Function(int?)? onHover;

  const BarGraph({
    super.key,
    required this.entries,
    required this.isDark,
    this.touchedIndex,
    this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        final isActive = i == touchedIndex;

        return MouseRegion(
          onEnter: (_) => onHover?.call(i),
          onExit: (_) => onHover?.call(null),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ChartLayout.barItemSpacing),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: ChartLayout.barHeight,
                        decoration: BoxDecoration(
                          color: ChartColors.bgBarColor(isDark),
                          borderRadius: BorderRadius.circular(ChartLayout.barBorderRadius),
                        ),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: e.value / 100,
                        child: Container(
                          height: ChartLayout.barHeight,
                          decoration: BoxDecoration(
                            color: ChartColors.mainColors[i % ChartColors.mainColors.length]
                                .withOpacity(isActive
                                    ? ChartLayout.barActiveOpacity
                                    : ChartLayout.barInactiveOpacity),
                            borderRadius: BorderRadius.circular(ChartLayout.barBorderRadius),
                            border: isActive
                                ? Border.all(
                                    color: ChartColors.highlightBorder,
                                    width: ChartLayout.barActiveBorderWidth,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ChartLayout.barValueSpacing),
                SizedBox(
                  width: ChartLayout.barValueWidth,
                  child: Text(
                    '${e.value.toStringAsFixed(1)}%',
                    style: ChartTextStyle.value(isDark: isDark, isActive: isActive),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}