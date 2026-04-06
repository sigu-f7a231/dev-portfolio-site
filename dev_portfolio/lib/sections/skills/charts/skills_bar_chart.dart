import 'package:flutter/material.dart';
import 'bar_chart/bar_graph.dart';
import 'bar_chart/bar_legend.dart';
import '../../config/skills_bar_chart_config.dart';

class SkillsBarChart extends StatefulWidget {
  final List<MapEntry<String, double>> entries;
  final bool isDark;

  const SkillsBarChart({
    super.key,
    required this.entries,
    required this.isDark,
  });

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
        /// ===== BarGraph =====
        Expanded(
          flex: BarChartLayout.barGraphFlex,
          child: BarGraph(
            entries: widget.entries,
            isDark: widget.isDark,
            touchedIndex: touchedIndex,
            onHover: _onHover,
          ),
        ),

        const SizedBox(width: BarChartLayout.barSpacing),

        /// ===== Legend =====
        Expanded(
          flex: BarChartLayout.barLegendFlex,
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