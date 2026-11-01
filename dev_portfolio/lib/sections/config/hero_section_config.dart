// lib/sections/config/hero_section_config.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

// 色は lib/theme/app_colors.dart（hero*）、文字・ボタンの見た目は lib/theme/app_styles.dart で管理

// 表示する文言（名前・紹介文など）は lib/constants/app_texts.dart の HeroContent

/// Home のレイアウト
class HeroSectionConfig {
  /// セクション高さ（画面の高さ − ヘッダー分。最低 560）
  static double height(BuildContext context) =>
      math.max(560.0, MediaQuery.of(context).size.height - 72);

  /// この幅以上で「テキスト左・YAML 右」の 2 カラムにする
  static const double wideBreakpoint = 900;

  /// この幅未満では YAML カードを出さない（スマホ）
  static const double codeCardBreakpoint = 600;

  /// 中身の最大幅
  static const double maxContentWidth = 1080;

  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 32, vertical: 48);

  // 文字サイズ（wide / narrow）
  static const double nameFontSizeWide = 57; // M3 display large
  static const double nameFontSizeNarrow = 36; // M3 display small
  static const double roleFontSize = 22; // M3 title large
  static const double taglineFontSize = 16; // M3 body large

  /// 紹介文の最大幅（1 行が長くなりすぎないように）
  static const double taglineMaxWidth = 560;

  static const double codeCardWidth = 380;
}
