import 'package:flutter/material.dart';
import 'pie_chart/pie_graph.dart';
import 'pie_chart/pie_legend.dart';

class SkillsPieChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isDark;

  const SkillsPieChart({super.key, required this.data, required this.isDark});

  @override
  State<SkillsPieChart> createState() => _SkillsPieChartState();
}

class _SkillsPieChartState extends State<SkillsPieChart> {
  int? hoveredIndex;
  int? selectedIndex;

  void _handleHover(int? idx) {
    setState(() {
      hoveredIndex = idx == -1 ? null : idx;
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
        Padding(
          padding: const EdgeInsets.only(top: 24.0, left: 32.0),
          child: PieGraph(
            data: widget.data,
            isDark: widget.isDark,
            hoveredIndex: hoveredIndex,
            selectedIndex: selectedIndex,
            onHover: _handleHover,
            onSelect: _handleSelect,
          ),
        ),
        const SizedBox(width: 100),
        Expanded(
          child: PieLegend(
            data: widget.data,
            isDark: widget.isDark,
            hoveredIndex: hoveredIndex,
            selectedIndex: selectedIndex,
            onHover: (idx) => _handleHover(idx),
            onSelect: (idx) => _handleSelect(idx),
          ),
        ),
      ],
    );
  }
}