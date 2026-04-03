// lib/sections/skills/charts/chart_config.dart
import 'package:flutter/material.dart';

/// 共通カラー設定
class ChartColors {
  /// グラフのメインカラー配列（Pie/Bar共通）
  static const mainColors = [
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
    Colors.yellowAccent,
    Colors.pinkAccent,
  ];

  /// 強調時の枠線
  static const highlightBorder = Colors.orangeAccent;

  /// BarChart 背景バー
  static Color bgBarColor(bool isDark) => isDark ? Colors.white10 : Colors.black12;
}

/// レイアウト設定（サイズやスペーシング）
class ChartLayout {
  // ---------- PieChart ----------
  static const pieRadius = 100.0;
  static const pieActiveRadius = 120.0;
  static const pieCenterRadius = 60.0;
  static const pieSectionsSpace = 4.0;
  static const pieActiveBorderWidth = 3.0;

  // PieChart 凡例
  static const pieLegendColorSize = 16.0;
  static const pieLegendColorRadius = 4.0;
  static const pieLegendSpacingItem = 8.0;

  // ---------- BarChart ----------
  static const barHeight = 24.0;
  static const barBorderRadius = 4.0;
  static const barActiveOpacity = 0.8;
  static const barActiveBorderWidth = 2.0;

  static const barItemSpacing = 6.0;
  static const barValueSpacing = 12.0;
  static const barValueWidth = 50.0;

  static const barLegendSpacing = 32.0;
  static const barLegendColorSize = 16.0;
  static const barLegendColorRadius = 4.0;
  static const barLegendSpacingItem = 8.0;
}

/// テキストスタイル
class ChartTextStyle {
  /// 凡例ラベル
  static TextStyle label({required bool isDark, required bool isActive}) {
    return TextStyle(
      color: isActive ? ChartColors.highlightBorder : (isDark ? Colors.white : Colors.black87),
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }

  /// 値（％など）
  static TextStyle value({required bool isDark, required bool isActive}) {
    return TextStyle(
      color: isActive ? ChartColors.highlightBorder : (isDark ? Colors.white70 : Colors.black54),
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }
}