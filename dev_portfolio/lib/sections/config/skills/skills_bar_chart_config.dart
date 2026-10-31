// lib/sections/config/skills/skills_bar_chart_config.dart
// 色は lib/theme/app_colors.dart（chartSeries / chartHighlight / chartTrack）、
// ラベル・値の文字スタイルは lib/theme/app_styles.dart（chartLabel / chartValue）で管理

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
