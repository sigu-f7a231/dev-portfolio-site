// lib/sections/config/about_section_config.dart
import 'package:flutter/material.dart';

// 色は lib/theme/app_colors.dart（aboutBackground / aboutDivider / aboutAccent）、
// 文字の見た目は lib/theme/app_styles.dart（about*）で管理

// 表示する文言（自己紹介など）は lib/constants/app_texts.dart の AboutContent

/// About のレイアウト
class AboutSectionConfig {
  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 32, vertical: 96);

  /// 中身の最大幅（1 行が長くなりすぎないように）
  static const double maxContentWidth = 760;

  /// この幅以上で「見出し｜説明」を横並びにする
  static const double wideBreakpoint = 640;

  /// 横並び時の見出し列の幅
  static const double termWidth = 140;

  static const double headingFontSize = 36; // M3 display small
  static const double introFontSize = 16; // M3 body large

  static const SizedBox headingSpacing = SizedBox(height: 24);
  static const SizedBox introSpacing = SizedBox(height: 48);
  static const EdgeInsets rowPadding = EdgeInsets.symmetric(vertical: 20);
  static const SizedBox closingSpacing = SizedBox(height: 48);

  /// 締めの一文の左の縦線
  static const double closingBarWidth = 4;
  static const double closingBarGap = 16;
}
