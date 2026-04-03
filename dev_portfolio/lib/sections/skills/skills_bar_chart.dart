import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SkillsBarChart extends StatelessWidget {
  final Map<String, double> data;
  final bool isDark;

  const SkillsBarChart({super.key, required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final barColor = isDark ? Colors.tealAccent : Colors.orangeAccent;
    final barWidth = 40.0;
    final barSpacing = 50.0;

    final labels = data.keys.toList();
    final values = data.values.toList();

    String formatLabel(String text) {
      final parts = text.split(RegExp(r'[/ ]+'));
      if (parts.length <= 3) return parts.join('\n');
      return '${parts[0]}\n${parts[1]}\n${parts.sublist(2).join(" ")}';
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: labels.length * (barWidth + barSpacing),
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
                  reservedSize: 50,
                  getTitlesWidget: (val, meta) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      val.toInt().toString(),
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black),
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
                    if (idx < 0 || idx >= labels.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: barWidth + 20,
                        child: Text(
                          formatLabel(labels[idx]),
                          textAlign: TextAlign.center,
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(
              values.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    color: barColor,
                    width: barWidth,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}