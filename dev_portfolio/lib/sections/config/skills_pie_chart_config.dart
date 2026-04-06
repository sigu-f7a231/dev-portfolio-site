// lib/sections/config/skills_pie_chart_config.dart
import 'package:flutter/material.dart';

/// ========================================
/// PieChart カラー設定
/// ========================================
class PieChartColors {
  static const List<Color> mainColors = [
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
    Colors.yellowAccent,
    Colors.pinkAccent,
  ];

  static const Color highlightBorder = Colors.orangeAccent;

  static Color pieColor(Color base, bool isActive) {
    if (!isActive) return base;

    return HSLColor.fromColor(base)
        .withLightness(PieChartLayout.pieHighlightLightness)
        .toColor();
  }

  static BorderSide pieBorder(bool isActive) {
    return isActive
        ? BorderSide(
            color: highlightBorder,
            width: PieChartLayout.pieActiveBorderWidth,
          )
        : BorderSide(
            color: Colors.transparent,
            width: PieChartLayout.pieInactiveBorderWidth,
          );
  }
}

/// ========================================
/// PieChart レイアウト
/// ========================================
class PieChartLayout {
  // ===== サイズ =====
  static const double pieSize = 300.0;

  // ===== 円 =====
  static const double pieRadius = 100.0;
  static const double pieActiveRadius = 120.0;
  static const double pieCenterRadius = 60.0;
  static const double pieSectionsSpace = 4.0;

  // ===== 枠線 =====
  static const double pieInactiveBorderWidth = 0.0;
  static const double pieActiveBorderWidth = 3.0;

  // ===== 明るさ =====
  static const double pieHighlightLightness = 0.7;

  // ===== Padding =====
  static const double pieTopPadding = 24.0;
  static const double pieLeftPadding = 32.0;

  /// 🔥 ここが追加分
  static const EdgeInsets padding = EdgeInsets.all(16.0);

  /// 🔥 overflow防止用の最小サイズ
  static const double minWidth = 400.0;
  static const double minHeight = 300.0;

  // ===== Row間隔 =====
  static const double pieLegendSpacingRow = 100.0;

  // ===== Legend =====
  static const double pieLegendColorSize = 16.0;
  static const double pieLegendColorRadius = 4.0;
  static const double pieLegendSpacingItem = 8.0;
  static const double pieLegendItemSpacing = 4.0;
  static const double pieLegendValueWidth = 50.0;
}

/// ========================================
/// テキストスタイル
/// ========================================
class PieChartTextStyle {
  static TextStyle label({
    required bool isDark,
    required bool isActive,
  }) {
    return TextStyle(
      color: isActive
          ? PieChartColors.highlightBorder
          : (isDark ? Colors.white : Colors.black87),
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }

  static TextStyle value({
    required bool isDark,
    required bool isActive,
  }) {
    return TextStyle(
      color: isActive
          ? PieChartColors.highlightBorder
          : (isDark ? Colors.white70 : Colors.black54),
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }
}