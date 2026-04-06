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

  /// 非アクティブ色の opacity
  static const double inactiveOpacityDark = 0.6;
  static const double inactiveOpacityLight = 0.35;

  /// ホバー時の opacity
  static const double hoverOpacityDark = 0.75;
  static const double hoverOpacityLight = 0.55;

  /// 選択時の opacity
  static const double selectedOpacityDark = 1.0;
  static const double selectedOpacityLight = 1.0;

  /// PieChart 色（非アクティブ・ホバー・選択で変化）
  static Color pieColor(
    Color base, {
    required bool isDark,
    required bool isHovered,
    required bool isSelected,
  }) {
    double opacity;

    if (isSelected) {
      opacity = isDark ? selectedOpacityDark : selectedOpacityLight;
    } else if (isHovered) {
      opacity = isDark ? hoverOpacityDark : hoverOpacityLight;
    } else {
      opacity = isDark ? inactiveOpacityDark : inactiveOpacityLight;
    }

    return base.withOpacity(opacity);
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

  /// 🔥 ここが追加分
  static const EdgeInsets padding = EdgeInsets.all(16.0);

  /// 🔥 overflow防止用の最小サイズ
  static const double minWidth = 400.0;
  static const double minHeight = 300.0;

  static const double pieSize = 300.0;

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

/// ========================================
/// PieChart テキストスタイル
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