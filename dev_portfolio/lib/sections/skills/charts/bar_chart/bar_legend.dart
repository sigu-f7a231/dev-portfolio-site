import 'package:flutter/material.dart';
import '../chart_config.dart';

class BarLegend extends StatelessWidget {
  final List<MapEntry<String, double>> entries;
  final int? touchedIndex;
  final bool isDark;

  const BarLegend({
    super.key,
    required this.entries,
    required this.touchedIndex,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        final isActive = i == touchedIndex;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: ChartLayout.barItemSpacing),
          child: Row(
            children: [
              Container(
                width: ChartLayout.barLegendColorSize,
                height: ChartLayout.barLegendColorSize,
                decoration: BoxDecoration(
                  color: ChartColors.mainColors[i % ChartColors.mainColors.length],
                  borderRadius:
                      BorderRadius.circular(ChartLayout.barLegendColorRadius),
                  border: isActive
                      ? Border.all(
                          color: ChartColors.highlightBorder,
                          width: ChartLayout.barActiveBorderWidth)
                      : null,
                ),
              ),
              const SizedBox(width: ChartLayout.barLegendSpacingItem),
              Expanded(
                child: Text(
                  e.key,
                  style: ChartTextStyle.label(isDark: isDark, isActive: isActive),
                ),
              ),
              SizedBox(
                width: ChartLayout.barValueWidth,
                child: Text(
                  '${e.value.toStringAsFixed(1)}%',
                  style: ChartTextStyle.value(isDark: isDark, isActive: isActive),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}