import 'package:flutter/material.dart';
import 'pie_chart/pie_graph.dart';
import 'pie_chart/pie_legend.dart';
import '../config/skills_chart_config.dart';

class SkillsPieChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const SkillsPieChart({
    super.key,
    required this.data,
    required this.isDark,
  });

  @override
  State<SkillsPieChart> createState() => _SkillsPieChartState();
}

class _SkillsPieChartState extends State<SkillsPieChart> {
  int? hoveredIndex;
  int? selectedIndex;

  void _handleHover(int? idx) {
    setState(() {
      hoveredIndex = idx;
    });
  }

  void _handleSelect(int? idx) {
    setState(() {
      selectedIndex = selectedIndex == idx ? null : idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ■ Pie グラフ
        Padding(
          padding: const EdgeInsets.only(
            top: ChartLayout.pieTopPadding,
            left: ChartLayout.pieLeftPadding,
          ),
          child: PieGraph(
            data: widget.data,
            isDark: widget.isDark,
            hoveredIndex: hoveredIndex,
            selectedIndex: selectedIndex,
            onHover: _handleHover,
            onSelect: _handleSelect,
          ),
        ),

        SizedBox(width: ChartLayout.pieLegendSpacingRow),

        // ■ Legend
        Expanded(
          child: PieLegend(
            data: widget.data,
            isDark: widget.isDark,
            hoveredIndex: hoveredIndex,
            selectedIndex: selectedIndex,
            onHover: _handleHover,
            onSelect: _handleSelect,
          ),
        ),
      ],
    );
  }
}