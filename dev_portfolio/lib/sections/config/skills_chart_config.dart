// lib/sections/skills/charts/chart_config.dart
import 'package:flutter/material.dart';

/// ========================================
/// カラー設定（Pie / Bar 共通）
/// ========================================
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

  /// PieChart 色（アクティブ時に明るくする）
  static Color pieColor(Color base, bool isActive) {
    if (!isActive) return base;
    return HSLColor.fromColor(base)
        .withLightness(ChartLayout.pieHighlightLightness)
        .toColor();
  }

  /// PieChart 枠線
  static BorderSide pieBorder(bool isActive) {
    return isActive
        ? BorderSide(
            color: highlightBorder,
            width: ChartLayout.pieActiveBorderWidth,
          )
        : BorderSide(
            color: Colors.transparent,
            width: ChartLayout.pieInactiveBorderWidth,
          );
  }
}

/// ========================================
/// レイアウト設定（サイズ・スペーシング）
/// ========================================
class ChartLayout {
// ---------- PieChart ----------
static const pieRadius = 100.0;
static const pieActiveRadius = 120.0;
static const pieCenterRadius = 60.0;
static const pieSectionsSpace = 4.0;
static const pieInactiveBorderWidth = 0.0;
static const pieActiveBorderWidth = 3.0;
static const pieHighlightLightness = 0.7;

// PieChart 全体サイズ
static const double pieSize = 300.0;

// PieChart 凡例
static const pieLegendColorSize = 16.0;
static const pieLegendColorRadius = 4.0;
static const pieLegendSpacingItem = 8.0;
static const pieLegendItemSpacing = 4.0;
static const pieLegendValueWidth = 50.0;

// SkillsPieChart padding
static const pieTopPadding = 24.0;
static const pieLeftPadding = 32.0;
static const pieLegendSpacingRow = 100.0;

  // ---------- BarChart ----------
  static const barHeight = 24.0;
  static const barBorderRadius = 4.0;
  static const barActiveOpacity = 0.8;
  static const barInactiveOpacity = 1.0;
  static const barActiveBorderWidth = 2.0;

  static const barItemSpacing = 6.0;
  static const barValueSpacing = 12.0;
  static const barValueWidth = 50.0;

  // BarChart 凡例
  static const barLegendSpacing = 32.0;
  static const barLegendColorSize = 16.0;
  static const barLegendColorRadius = 4.0;
  static const barLegendSpacingItem = 8.0;

  // Bar chart と Legend の間隔
  static const barSpacing = 32.0;

  // BarChart と Legend の Flex / 間隔
  static const int barGraphFlex = 2;    // ← BarGraph の flex
  static const int barLegendFlex = 2;   // ← BarLegend の flex
}

/// ========================================
/// テキストスタイル
/// ========================================
class ChartTextStyle {
  /// 凡例ラベル
  static TextStyle label({required bool isDark, required bool isActive}) {
    return TextStyle(
      color: isActive
          ? ChartColors.highlightBorder
          : (isDark ? Colors.white : Colors.black87),
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }

  /// 値（％など）
  static TextStyle value({required bool isDark, required bool isActive}) {
    return TextStyle(
      color: isActive
          ? ChartColors.highlightBorder
          : (isDark ? Colors.white70 : Colors.black54),
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }
}