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

  /// この幅以上で名前を大きくする
  static const double wideBreakpoint = 900;

  /// 中身の最大幅（すべて中央寄せ）
  static const double maxContentWidth = 960;

  static const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 32, vertical: 48);

  // 文字サイズ（wide / narrow）
  static const double nameFontSizeWide = 57; // M3 display large
  static const double nameFontSizeNarrow = 36; // M3 display small
  static const double roleFontSize = 22; // M3 title large
  static const double taglineFontSize = 16; // M3 body large

  /// 紹介文の最大幅（1 行が長くなりすぎないように）
  static const double taglineMaxWidth = 560;

  /// ボタンとまとめの間
  static const double summaryGap = 48;

  /// まとめ：この幅以上で 3 つを横に並べる（未満は縦に積む）
  static const double summaryRowBreakpoint = 720;

  /// まとめを縦に積むときの最大幅
  static const double summaryColumnMaxWidth = 420;

  /// まとめの 1 枚の中の余白・最低の高さ・アイコンの大きさ
  static const EdgeInsets summaryCardPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 18);
  static const double summaryCardMinHeight = 132;
  static const double summaryIconSize = 20;

  // まとめの文字の大きさ（M3：label medium / headline small / body small）
  static const double summaryLabelFontSize = 12;
  static const double summaryValueFontSize = 24;
  static const double summaryValueSmallFontSize = 17; // 直近のプロジェクト名（長いので小さめ）
  static const double summarySubFontSize = 12;
}
