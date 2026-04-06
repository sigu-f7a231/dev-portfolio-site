// lib/sections/config/hero_section_config.dart
import 'package:flutter/material.dart';

class HeroSectionConfig {
  // 背景色
  static Color backgroundColor(bool isDark) =>
      isDark ? Colors.grey[900]! : Colors.blueAccent;

  // セクション高さ
  static double height(BuildContext context) => MediaQuery.of(context).size.height;

  // テキストスタイル
  static const double titleFontSize = 36;
  static const Color titleColor = Colors.white;
  static const TextAlign titleAlign = TextAlign.center;
}