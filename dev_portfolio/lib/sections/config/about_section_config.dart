// lib/sections/config/about_section_config.dart
import 'package:flutter/material.dart';

class AboutSectionConfig {
  // 背景色
  static Color backgroundColor(bool isDark) =>
      isDark ? Colors.grey[900]! : Colors.teal[200]!;

  // 文字色
  static Color textColor(bool isDark) => isDark ? Colors.white : Colors.black87;

  // セクション全体のパディング
  static const EdgeInsets padding =
      EdgeInsets.symmetric(horizontal: 40, vertical: 80);

  // セクションタイトル
  static const double titleFontSize = 36;
  static const FontWeight titleFontWeight = FontWeight.bold;

  // テキスト本文
  static const double bodyFontSize = 20;
  static const FontStyle bodyFontStyleNormal = FontStyle.normal;
  static const FontStyle bodyFontStyleItalic = FontStyle.italic;

  // 高さ（縦スペース）
  static const SizedBox sectionSpacing = SizedBox(height: 40);
  static const SizedBox textSpacing = SizedBox(height: 20);
}