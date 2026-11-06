import 'package:flutter/material.dart';
import 'bar_chart/bar_graph.dart';
import 'bar_chart/bar_legend.dart';
import '../../config/skills/skills_bar_chart_config.dart';
import '../../config/skills/skills_widgets_card_config.dart';

class SkillsBarChart extends StatefulWidget {
  final List<MapEntry<String, double>> entries;

  const SkillsBarChart({
    super.key,
    required this.entries,
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
    final graph = BarGraph(
      entries: widget.entries,
      touchedIndex: touchedIndex,
      onHover: _onHover,
    );
    final legend = BarLegend(
      entries: widget.entries,
      touchedIndex: touchedIndex,
      onHover: _onHover,
    );

    return LayoutBuilder(builder: (context, constraints) {
      // 狭い画面（スマホ）：グラフの下に凡例
      if (constraints.maxWidth < SkillsCardConfig.stackBreakpoint) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            graph,
            const SizedBox(height: BarChartLayout.barSpacing),
            legend,
          ],
        );
      }
      return _wide(graph, legend);
    });
  }

  Widget _wide(Widget graph, Widget legend) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ===== BarGraph =====
        Expanded(
          flex: BarChartLayout.barGraphFlex,
          child: graph,
        ),

        const SizedBox(width: BarChartLayout.barSpacing),

        /// ===== Legend =====
        Expanded(
          flex: BarChartLayout.barLegendFlex,
          child: legend,
        ),
      ],
    );
  }
}