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

  /// タブ名
  static const List<String> mainTabs = [
    'Work',
    'Private',
  ];
}

/// レイアウト設定
class SkillsLayout {
  static const double sectionPadding = 24;
  static const double spacing = 16;

  static const double cardWidth = 1000;
  static const double cardHeight = 500;
  static const double cardPadding = 16;

  static const double borderRadius = 16;

  static const double shadowBlur = 16;
  static const Offset shadowOffset = Offset(0, 8);
  static const double shadowOpacity = 0.12;
}

/// カラー設定
class SkillsColors {
  static Color background(bool isDark) =>
      isDark ? Colors.black : const Color(0xFFDADAE3);

  static Color card(bool isDark) =>
      isDark ? const Color(0xFF2A2A3D) : const Color(0xFFFDFDFD);

  static Color text(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF222222);

  static const Color accent = Colors.orangeAccent;
}

/// テキスト設定
class SkillsTextStyle {
  static const double titleSize = 28;
  static const double labelSize = 14;
  static const double valueSize = 12;

  static TextStyle title(bool isDark) => TextStyle(
        fontSize: titleSize,
        fontWeight: FontWeight.bold,
        color: SkillsColors.text(isDark),
      );

  static TextStyle label(bool isDark) => TextStyle(
        fontSize: labelSize,
        color: SkillsColors.text(isDark),
      );

  static TextStyle value(bool isDark) => TextStyle(
        fontSize: valueSize,
        color: isDark ? Colors.white70 : Colors.black54,
      );
}