// Skills のグラフ（円・棒）のテスト
// 対象：lib/sections/skills/charts/（skills_pie_chart / skills_bar_chart と、pie_chart・bar_chart の中身）
// - 上位 10 件より多ければ「その他」にまとめる・10 件以下ならまとめない
// - 凡例の上にマウスを乗せる / 離す、押して選ぶ / もう一度押して外す、円を押す
// - 狭い画面は縦に積み、広い画面は横に並べる。ライト / ダーク
//
// 実行：flutter test test/skills_charts_test.dart（frontend/ で）
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_sizes.dart';
import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/sections/config/skills/skills_pie_chart_config.dart';
import 'package:dev_portfolio/sections/skills/charts/bar_chart/bar_graph.dart';
import 'package:dev_portfolio/sections/skills/charts/bar_chart/bar_legend.dart';
import 'package:dev_portfolio/sections/skills/charts/pie_chart/pie_graph.dart';
import 'package:dev_portfolio/sections/skills/charts/pie_chart/pie_legend.dart';
import 'package:dev_portfolio/sections/skills/charts/skills_bar_chart.dart';
import 'package:dev_portfolio/sections/skills/charts/skills_pie_chart.dart';
import 'package:dev_portfolio/theme/app_theme.dart';

import 'test_assets.dart';

/// [n] 件の割合（合計 100%）。Tech 1 がいちばん大きく、ちょうど半分
Map<String, double> _data(int n) {
  if (n == 1) return {'Tech 1': 100};
  final rest = 50 / (n - 1);
  return {'Tech 1': 50, for (var i = 2; i <= n; i++) 'Tech $i': rest - i * 0.01};
}

Future<void> _pump(WidgetTester tester, Widget chart, {double width = 900, bool dark = false}) async {
  tester.view.physicalSize = Size(width, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: dark ? AppTheme.dark : AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: chart)),
  ));
  await tester.pumpAndSettle();
}

Future<TestGesture> _mouse(WidgetTester tester) async {
  final g = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await g.addPointer(location: Offset.zero);
  addTearDown(g.removePointer);
  return g;
}

PieGraph _pie(WidgetTester tester) => tester.widget<PieGraph>(find.byType(PieGraph));
BarGraph _bar(WidgetTester tester) => tester.widget<BarGraph>(find.byType(BarGraph));

void main() {
  setUpAll(loadAppFont);

  group('円グラフ', () {
    testWidgets('${AppSizes.chartTopN} 件より多ければ、残りを「その他」にまとめる', (tester) async {
      await _pump(tester, SkillsPieChart(data: _data(AppSizes.chartTopN + 4)));
      expect(find.text(AppTexts.chartOthers), findsOneWidget);
      expect(find.text('Tech ${AppSizes.chartTopN + 4}'), findsNothing);
    });

    testWidgets('${AppSizes.chartTopN} 件以下ならまとめない（1 件だけでも描ける）', (tester) async {
      await _pump(tester, SkillsPieChart(data: _data(AppSizes.chartTopN)));
      expect(find.text(AppTexts.chartOthers), findsNothing);
      await _pump(tester, SkillsPieChart(data: _data(1)));
      expect(find.text('Tech 1'), findsOneWidget);
    });

    testWidgets('凡例：押すと選び、もう一度押すと外す。別のものを押すと選び直す', (tester) async {
      await _pump(tester, SkillsPieChart(data: _data(5)));
      await tester.tap(find.text('Tech 1'));
      await tester.pumpAndSettle();
      expect(_pie(tester).selectedIndex, 0);
      await tester.tap(find.text('Tech 3'));
      await tester.pumpAndSettle();
      expect(_pie(tester).selectedIndex, 2);
      await tester.tap(find.text('Tech 3'));
      await tester.pumpAndSettle();
      expect(_pie(tester).selectedIndex, isNull);
    });

    testWidgets('凡例：マウスを乗せると強調し、離すと戻す', (tester) async {
      await _pump(tester, SkillsPieChart(data: _data(5)));
      final mouse = await _mouse(tester);
      await mouse.moveTo(tester.getCenter(find.text('Tech 2')));
      await tester.pumpAndSettle();
      expect(_pie(tester).hoveredIndex, 1);
      expect(tester.widget<PieLegend>(find.byType(PieLegend)).hoveredIndex, 1);
      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(_pie(tester).hoveredIndex, isNull);
    });

    testWidgets('円：扇を押すと選ぶ。マウスを乗せると強調、外へ出ると戻す', (tester) async {
      await _pump(tester, SkillsPieChart(data: _data(5)));
      final graph = _pie(tester);
      final scale = graph.size / PieChartLayout.pieSize;
      final r = (PieChartLayout.pieCenterRadius + PieChartLayout.pieRadius / 2) * scale;
      // 扇は 3 時の向きから時計回り。Tech 1（半分）は 0〜180°なので、45° の位置を押す
      final center = tester.getCenter(find.byType(PieGraph));
      final onFirst = center + Offset(math.cos(math.pi / 4), math.sin(math.pi / 4)) * r;

      await tester.tapAt(onFirst);
      await tester.pumpAndSettle();
      expect(_pie(tester).selectedIndex, 0);

      final mouse = await _mouse(tester);
      await mouse.moveTo(onFirst);
      await tester.pumpAndSettle();
      expect(_pie(tester).hoveredIndex, 0);
      await mouse.moveTo(const Offset(1, 1));
      await tester.pumpAndSettle();
      expect(_pie(tester).hoveredIndex, isNull);
    });

    testWidgets('円の真ん中（扇のない所）を押すと、選んだものを外す', (tester) async {
      await _pump(tester, SkillsPieChart(data: _data(5)));
      await tester.tap(find.text('Tech 1'));
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getCenter(find.byType(PieGraph)));
      await tester.pumpAndSettle();
      expect(_pie(tester).selectedIndex, isNull);
    });

    testWidgets('狭い画面は円の下に凡例、広い画面は横に並べる', (tester) async {
      await _pump(tester, SkillsPieChart(data: _data(5)), width: 400);
      expect(tester.getTopLeft(find.byType(PieLegend)).dy, greaterThan(tester.getBottomLeft(find.byType(PieGraph)).dy));
      await _pump(tester, SkillsPieChart(data: _data(5)), width: 1000);
      expect(tester.getTopLeft(find.byType(PieLegend)).dx, greaterThan(tester.getTopRight(find.byType(PieGraph)).dx));
    });

    for (final width in [400.0, 1000.0]) {
      testWidgets('ダーク（幅 $width）で、選んだ状態も描ける', (tester) async {
        await _pump(tester, SkillsPieChart(data: _data(12)), width: width, dark: true);
        await tester.tap(find.text('Tech 1'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('棒グラフ', () {
    List<MapEntry<String, double>> entries(int n) => _data(n).entries.toList();

    testWidgets('${AppSizes.chartTopN} 件より多ければ「その他」、以下ならまとめない', (tester) async {
      await _pump(tester, SkillsBarChart(entries: entries(AppSizes.chartTopN + 3)));
      expect(find.text(AppTexts.chartOthers), findsWidgets);
      await _pump(tester, SkillsBarChart(entries: entries(3)));
      expect(find.text(AppTexts.chartOthers), findsNothing);
    });

    testWidgets('凡例・棒にマウスを乗せると強調し、離すと戻す', (tester) async {
      await _pump(tester, SkillsBarChart(entries: entries(5)));
      final mouse = await _mouse(tester);

      await mouse.moveTo(tester.getCenter(find.text('Tech 2').first));
      await tester.pumpAndSettle();
      expect(_bar(tester).touchedIndex, 1);
      expect(tester.widget<BarLegend>(find.byType(BarLegend)).touchedIndex, 1);

      // グラフの下（何もない所）へ。左上の (1, 1) は 1 本目の棒の上になるので使わない
      await mouse.moveTo(tester.getBottomLeft(find.byType(SkillsBarChart)) + const Offset(10, 40));
      await tester.pumpAndSettle();
      expect(_bar(tester).touchedIndex, isNull);

      // 棒の行の上
      final firstBar = find.descendant(of: find.byType(BarGraph), matching: find.byType(MouseRegion)).first;
      await mouse.moveTo(tester.getCenter(firstBar));
      await tester.pumpAndSettle();
      expect(_bar(tester).touchedIndex, 0);
    });

    for (final (width, dark) in [(400.0, false), (1000.0, false), (400.0, true), (1000.0, true)]) {
      testWidgets('幅 $width・${dark ? 'ダーク' : 'ライト'}で描ける（0 件も）', (tester) async {
        await _pump(tester, SkillsBarChart(entries: entries(12)), width: width, dark: dark);
        await _pump(tester, const SkillsBarChart(entries: []), width: width, dark: dark);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
