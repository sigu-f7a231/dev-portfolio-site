// lib/sections/skills/config/skills_tab_bar_config.dart
import 'package:flutter/material.dart';

/// SkillsTabBar 専用設定
class SkillsTabBarConfig {
  // タブ文字サイズ
  static const double labelFontSize = 14;

  // ラベルカラー
  static Color labelColor(bool isDark) => isDark ? Colors.white70 : Colors.black87;

  // 選択時のラベルカラー
  static const Color selectedLabelColor = Colors.orangeAccent;

  // インジケータカラー
  static const Color indicatorColor = Colors.orangeAccent;

  // タブのスタイル
  static TextStyle tabTextStyle(bool isDark, {bool selected = false}) => TextStyle(
        fontSize: labelFontSize,
        color: selected ? selectedLabelColor : labelColor(isDark),
      );
}