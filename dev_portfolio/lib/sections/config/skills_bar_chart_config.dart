// lib/sections/config/bar_chart_config.dart
import 'package:flutter/material.dart';

/// ========================================
/// BarChart カラー設定
/// ========================================
class BarChartColors {
  /// メインカラー
  static const List<Color> mainColors = [
    Colors.blueAccent,
    Colors.orangeAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.redAccent,
    Colors.tealAccent,
  ];

  /// アクティブ時の枠線
  static const Color highlightBorder = Colors.orangeAccent;

  /// 背景バー色
  static Color bgBarColor(bool isDark) =>
      isDark ? Colors.white10 : Colors.black12;
}

/// ========================================
/// BarChart レイアウト設定
/// ========================================
class BarChartLayout {
  // ===== Bar本体 =====
  static const double barHeight = 24.0;
  static const double barBorderRadius = 4.0;

  static const double barActiveOpacity = 0.8;
  static const double barInactiveOpacity = 0.3;
  static const double barActiveBorderWidth = 2.0;

  static const double barItemSpacing = 6.0;
  static const double barValueSpacing = 12.0;
  static const double barValueWidth = 50.0;

  // ===== Legend =====
  static const double barLegendColorSize = 16.0;
  static const double barLegendColorRadius = 4.0;
  static const double barLegendSpacingItem = 8.0;

  // ===== Graph + Legend 間 =====
  static const double barSpacing = 32.0;

  // ===== Flex =====
  static const int barGraphFlex = 2;
  static const int barLegendFlex = 2;
}

/// ========================================
/// BarChart テキストスタイル
/// ========================================
class BarChartTextStyle {
  /// ラベル
  static TextStyle label({
    required bool isDark,
    required bool isActive,
  }) {
    return TextStyle(
      color: isActive
          ? BarChartColors.highlightBorder
          : (isDark ? Colors.white : Colors.black87),
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }

  /// 値（％）
  static TextStyle value({
    required bool isDark,
    required bool isActive,
  }) {
    return TextStyle(
      color: isActive
          ? BarChartColors.highlightBorder
          : (isDark ? Colors.white70 : Colors.black54),
      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
    );
  }
}