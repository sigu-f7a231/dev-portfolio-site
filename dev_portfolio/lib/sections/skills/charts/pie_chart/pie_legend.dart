// lib/sections/skills/charts/pie_chart/pie_legend.dart
import 'package:flutter/material.dart';
import '../../../config/skills/skills_pie_chart_config.dart';
import '../../../../utils/graph_utils.dart';

class PieLegend extends StatelessWidget {
  final Map<String, double> data;
  final bool isDark;
  final int? hoveredIndex;
  final int? selectedIndex;
  final Function(int) onHover;
  final Function(int) onSelect;

  const PieLegend({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: data.entries.mapIndexed((entry, index) {
        final isActive = index == hoveredIndex || index == selectedIndex;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => onHover(index),
          onExit: (_) => onHover(-1),
          child: GestureDetector(
            onTap: () => onSelect(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: PieChartLayout.pieLegendItemSpacing,
              ),
              child: Row(
                children: [
                  /// ■ カラーボックス
                  Container(
                    width: PieChartLayout.pieLegendColorSize,
                    height: PieChartLayout.pieLegendColorSize,
                    decoration: BoxDecoration(
                      color: PieChartColors.mainColors[
                          index % PieChartColors.mainColors.length],
                      borderRadius: BorderRadius.circular(
                        PieChartLayout.pieLegendColorRadius,
                      ),
                      border: isActive
                          ? Border.all(
                              color: PieChartColors.highlightBorder,
                              width: PieChartLayout.pieActiveBorderWidth,
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(
                    width: PieChartLayout.pieLegendSpacingItem,
                  ),

                  /// ■ ラベル
                  Expanded(
                    child: Text(
                      entry.key,
                      style: PieChartTextStyle.label(
                        isDark: isDark,
                        isActive: isActive,
                      ),
                    ),
                  ),

                  /// ■ 値
                  SizedBox(
                    width: PieChartLayout.pieLegendValueWidth,
                    child: Text(
                      '${entry.value.toStringAsFixed(1)}%',
                      textAlign: TextAlign.right,
                      style: PieChartTextStyle.value(
                        isDark: isDark,
                        isActive: isActive,
                      ),
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