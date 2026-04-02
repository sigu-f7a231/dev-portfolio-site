// lib/sections/skills/skills_pie_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SkillsPieChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const SkillsPieChart({super.key, required this.data, required this.isDark});

  @override
  State<SkillsPieChart> createState() => _SkillsPieChartState();
}

class _SkillsPieChartState extends State<SkillsPieChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final chartSize = screenWidth * 0.35;
    final maxRadius = chartSize / 2;

    return Center(
      child: SizedBox(
        width: chartSize + 40,
        height: chartSize + 40,
        child: PieChart(
          PieChartData(
            pieTouchData: PieTouchData(
              touchCallback: (event, response) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      response == null ||
                      response.touchedSection == null) {
                    touchedIndex = null;
                  } else {
                    touchedIndex = response.touchedSection!.touchedSectionIndex;
                  }
                });
              },
            ),
            sections: List.generate(entries.length, (i) {
              final e = entries[i];
              final isTouched = i == touchedIndex;
              final radius = isTouched ? maxRadius * 1.05 : maxRadius;
              final fontSize = isTouched ? 14.0 : 12.0;
              final percentage = e.value.round();

              return PieChartSectionData(
                value: e.value.toDouble(),
                title: '${e.key}\n$percentage%',
                radius: radius,
                color: widget.isDark
                    ? Colors.tealAccent.shade400
                    : Colors.primaries[i % Colors.primaries.length],
                titleStyle: TextStyle(
                  fontSize: fontSize,
                  color: widget.isDark ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                titlePositionPercentageOffset: 1.15,
              );
            }),
            sectionsSpace: 4,
            centerSpaceRadius: 0,
          ),
        ),
      ),
    );
  }
}