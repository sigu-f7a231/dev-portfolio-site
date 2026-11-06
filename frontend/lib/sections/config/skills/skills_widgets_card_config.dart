// lib/sections/config/skills/skills_widgets_card_config.dart
import 'package:flutter/material.dart';

/// SkillsCard 用の設定をまとめたクラス
/// 色・影の色は lib/theme/app_colors.dart（cardBackground / cardShadow）、
/// カードの見た目は lib/theme/app_styles.dart（AppStyles.card）で管理
class SkillsCardConfig {
  /// カードの最大幅（狭い画面では画面幅に合わせる）
  static const double maxWidth = 800;

  /// カードの最小の高さ（読み込み中・データなしの表示もこの高さ）
  static const double minHeight = 400;

  /// カード内の幅がこれ未満なら、グラフと凡例を縦に並べる
  static const double stackBreakpoint = 560;

  /// 内側の余白
  static const double padding = 16;

  /// 角丸
  static const double borderRadius = 12;

  /// シャドウ設定
  static const double shadowBlur = 8;
  static const Offset shadowOffset = Offset(0, 4);
}
