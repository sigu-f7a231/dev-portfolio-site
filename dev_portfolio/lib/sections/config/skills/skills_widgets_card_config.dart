// lib/sections/config/skills/skills_widgets_card_config.dart
import 'package:flutter/material.dart';

/// SkillsCard 用の設定をまとめたクラス
/// 色・影の色は lib/theme/app_colors.dart（cardBackground / cardShadow）、
/// カードの見た目は lib/theme/app_styles.dart（AppStyles.card）で管理
class SkillsCardConfig {
  /// カードサイズ
  static const double width = 800;
  static const double height = 400;

  /// 内側の余白
  static const double padding = 16;

  /// 角丸
  static const double borderRadius = 12;

  /// シャドウ設定
  static const double shadowBlur = 8;
  static const Offset shadowOffset = Offset(0, 4);
}
