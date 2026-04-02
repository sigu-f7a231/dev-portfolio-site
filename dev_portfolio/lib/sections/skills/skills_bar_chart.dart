// lib/sections/skills/skills_bar_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SkillsBarChart extends StatelessWidget {
  final Map<String, double> data;
  final bool isDark;

  const SkillsBarChart({super.key, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bars = data.entries.toList();
    final barColor = isDark ? Colors.tealAccent : Colors.orangeAccent;
    final barWidth = 40.0;
    final barSpacing = bars.length < 5 ? 50.0 : 35.0;
    final maxItemCount = 8;
    final chartWidth = maxItemCount * (barWidth + barSpacing) + 60;

    String formatLabel(String text) {
      final parts = text.split(RegExp(r'[/ ]+'));
      if (parts.length <= 3) return parts.join('\n');
      return '${parts[0]}\n${parts[1]}\n${parts.sublist(2).join(" ")}';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        height: 380,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 100,
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 110,
                  getTitlesWidget: (val, meta) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      val.toInt().toString(),
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 70,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= bars.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: barWidth + 20,
                        child: Text(
                          formatLabel(bars[idx].key),
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: [
              ...List.generate(
                bars.length,
                (i) => BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: bars[i].value,
                      color: barColor,
                      width: barWidth,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
              BarChartGroupData(
                x: bars.length,
                barRods: [
                  BarChartRodData(toY: 0, width: barWidth),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}