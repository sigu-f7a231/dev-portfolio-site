// lib/sections/skills/charts/skills_bar_chart.dart
import 'package:flutter/material.dart';
import 'bar_chart/bar_graph.dart';
import 'bar_chart/bar_legend.dart';
import '../../config/skills_chart_config.dart';

class SkillsBarChart extends StatefulWidget {
  final List<MapEntry<String, double>> entries;
  final bool isDark;

  const SkillsBarChart({super.key, required this.entries, required this.isDark});

  @override
  State<SkillsBarChart> createState() => _SkillsBarChartState();
}

class _SkillsBarChartState extends State<SkillsBarChart> {
  int? touchedIndex;

  void _onHover(int? index) {
    setState(() {
      touchedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // BarGraph
        Expanded(
          flex: ChartLayout.barGraphFlex,
          child: BarGraph(
            entries: widget.entries,
            isDark: widget.isDark,
            touchedIndex: touchedIndex,
            onHover: _onHover,
          ),
        ),
        const SizedBox(width: ChartLayout.barSpacing),
        // BarLegend
        Expanded(
          flex: ChartLayout.barLegendFlex,
          child: BarLegend(
            entries: widget.entries,
            isDark: widget.isDark,
            touchedIndex: touchedIndex,
            onHover: _onHover,
          ),
        ),
      ],
    );
  }
}