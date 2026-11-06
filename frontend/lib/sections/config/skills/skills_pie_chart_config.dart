// lib/sections/config/skills/skills_pie_chart_config.dart
// 色は lib/theme/app_colors.dart、ラベル・値の文字スタイルは lib/theme/app_styles.dart で管理
import 'package:flutter/material.dart';

/// ========================================
/// PieChart 透明度（色そのものは lib/theme/app_colors.dart の chartSeries）
/// ========================================
class PieChartOpacity {
  /// 非アクティブ時
  static const double inactiveDark = 0.6;
  static const double inactiveLight = 0.35;

  /// ホバー時
  static const double hoverDark = 0.75;
  static const double hoverLight = 0.55;

  /// 選択時
  static const double selectedDark = 1.0;
  static const double selectedLight = 1.0;

  /// 状態に応じた透明度
  static double of({
    required bool isDark,
    required bool isHovered,
    required bool isSelected,
  }) {
    if (isSelected) return isDark ? selectedDark : selectedLight;
    if (isHovered) return isDark ? hoverDark : hoverLight;
    return isDark ? inactiveDark : inactiveLight;
  }
}

/// ========================================
/// PieChart レイアウト
/// ========================================
class PieChartLayout {
  // ===== サイズ =====

  static const EdgeInsets padding = EdgeInsets.all(16.0);

  /// 円グラフの大きさ（基準）。狭い画面ではこれより小さくし、半径も同じ比率で縮める
  static const double pieSize = 300.0;

  /// 縦並びのとき、選択して外側に広がった分が欠けないよう左右に取る余白
  static const double pieStackedInset = 32.0;

  /// 縦並びのときの円と凡例の間
  static const double pieLegendSpacingColumn = 24.0;

  // ===== 円 =====
  static const double pieRadius = 100.0;
  static const double pieActiveRadius = 120.0;
  static const double pieCenterRadius = 60.0;
  static const double pieSectionsSpace = 4.0;

  // ===== 枠線 =====
  static const double pieInactiveBorderWidth = 0.0;
  static const double pieActiveBorderWidth = 3.0;

  // ===== 明るさ（選択時ハイライト用）=====
  static const double pieHighlightLightness = 0.7;

  // ===== Padding =====
  static const double pieTopPadding = 24.0;
  static const double pieLeftPadding = 32.0;

  // ===== Row間隔 =====
  static const double pieLegendSpacingRow = 100.0;

  // ===== Legend =====
  static const double pieLegendColorSize = 16.0;
  static const double pieLegendColorRadius = 4.0;
  static const double pieLegendSpacingItem = 8.0;
  static const double pieLegendItemSpacing = 4.0;
  static const double pieLegendValueWidth = 50.0;
}
