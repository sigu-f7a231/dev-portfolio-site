import 'package:flutter/material.dart';

/// Skills セクション全体の設定
class SkillsSectionConfig {
  /// カテゴリ一覧
  static const List<String> categories = [
    'skills',
    'server_os',
    'db',
    'tools_fw',
  ];

  /// メインタブ名
  static const List<String> mainTabs = [
    'Work',
    'Private',
  ];
}

/// 共通レイアウト設定
class SkillsLayout {
  static const double sectionPadding = 24;
  static const double spacing = 16;
}

/// カラー設定
class SkillsColors {
  static Color background(bool isDark) =>
      isDark ? Colors.black : const Color(0xFFDADAE3);

  static Color shadow(bool isDark) =>
      Colors.black.withOpacity(isDark ? 0.2 : 0.1);
}