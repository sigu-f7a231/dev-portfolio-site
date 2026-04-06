// lib/sections/skills/config/skills_card_config.dart
import 'package:flutter/material.dart';

/// SkillsCard 用の設定をまとめたクラス
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
  static const double shadowOpacity = 0.1;

  /// 背景色
  static Color background(bool isDark) => isDark ? Colors.grey[850]! : Colors.white;

  // static メソッドで定義
  static Color cardColor(bool isDark) =>
      isDark ? Colors.grey[850]! : Colors.white;
}

