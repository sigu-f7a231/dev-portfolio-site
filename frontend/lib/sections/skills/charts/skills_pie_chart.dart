import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'pie_chart/pie_graph.dart';
import 'pie_chart/pie_legend.dart';
import '../../config/skills/skills_pie_chart_config.dart';
import '../../config/skills/skills_widgets_card_config.dart';

class SkillsPieChart extends StatefulWidget {
  final Map<String, double> data;

  const SkillsPieChart({
    super.key,
    required this.data,
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

  Widget _pie(double size) => SizedBox(
        width: size,
        height: size,
        child: PieGraph(
          data: widget.data,
          size: size,
          hoveredIndex: hoveredIndex,
          selectedIndex: selectedIndex,
          onHover: _handleHover,
          onSelect: _handleSelect,
        ),
      );

  Widget _legend() => PieLegend(
        data: widget.data,
        hoveredIndex: hoveredIndex,
        selectedIndex: selectedIndex,
        onHover: (idx) {
          _handleHover(idx == -1 ? null : idx);
        },
        onSelect: _handleSelect,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: PieChartLayout.padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 狭い画面（スマホ）：円を幅に合わせて縮め、その下に凡例
          if (constraints.maxWidth < SkillsCardConfig.stackBreakpoint) {
            final size = math.min(
              PieChartLayout.pieSize,
              constraints.maxWidth - PieChartLayout.pieStackedInset * 2,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: PieChartLayout.pieTopPadding),
                Center(child: _pie(size)),
                const SizedBox(
                  height: PieChartLayout.pieTopPadding +
                      PieChartLayout.pieLegendSpacingColumn,
                ),
                _legend(),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top: PieChartLayout.pieTopPadding,
                  left: PieChartLayout.pieLeftPadding,
                ),
                child: _pie(PieChartLayout.pieSize),
              ),
              const SizedBox(width: PieChartLayout.pieLegendSpacingRow),
              Expanded(child: _legend()),
            ],
          );
        },
      ),
    );
  }
}
