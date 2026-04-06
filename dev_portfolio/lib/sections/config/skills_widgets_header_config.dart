// lib/sections/skills/config/skills_header_config.dart
import 'package:flutter/material.dart';

/// SkillsHeader 専用の設定
class SkillsHeaderConfig {
  // タイトル設定
  static const double titleFontSize = 28;
  static const FontWeight titleFontWeight = FontWeight.bold;

  // ラベル (Pie切替用) 設定
  static const double labelFontSize = 14;

  // Row 内スペーシング
  static const double spacingBetweenTitleAndSwitch = 16;

  // Switch のアクティブカラー
  static const Color switchActiveColor = Colors.orangeAccent;

  // Padding
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);

  // テキストカラー
  static Color titleColor(bool isDark) => isDark ? Colors.white : const Color(0xFF222222);
  static Color labelColor(bool isDark) => isDark ? Colors.white70 : Colors.black87;
}