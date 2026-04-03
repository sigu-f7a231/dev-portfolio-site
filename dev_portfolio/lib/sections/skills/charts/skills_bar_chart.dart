import 'package:flutter/material.dart';
import 'bar_chart/bar_graph.dart';
import 'bar_chart/bar_legend.dart';

class SkillsBarChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const SkillsBarChart({super.key, required this.data, required this.isDark});

  @override
  State<SkillsBarChart> createState() => _SkillsBarChartState();
}

class _SkillsBarChartState extends State<SkillsBarChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      children: [
        Expanded(flex: 2, child: BarGraph(entries: entries, touchedIndex: touchedIndex, isDark: widget.isDark)),
        const SizedBox(width: 32),
        Expanded(flex: 2, child: BarLegend(entries: entries, touchedIndex: touchedIndex, isDark: widget.isDark)),
      ],
    );
  }
}