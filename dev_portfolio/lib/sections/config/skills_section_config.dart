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

  // Card 用
  static const double cardWidth = 1000;
  static const double cardHeight = 500;
  static const double cardPadding = 16;
  static const double borderRadius = 16;

  // Card Shadow
  static const double shadowBlur = 16;
  static const Offset shadowOffset = Offset(0, 8);
  static const double shadowOpacity = 0.12;

  // TabBar 関連
  static const double tabBarHeight = 48;
}

/// カラー設定
class SkillsColors {
  static Color background(bool isDark) =>
      isDark ? Colors.black : const Color(0xFFDADAE3);

  static Color card(bool isDark) =>
      isDark ? const Color(0xFF2A2A3D) : const Color(0xFFFDFDFD);

  static Color text(bool isDark) =>
      isDark ? Colors.white : const Color(0xFF222222);

  static Color accent(bool isDark) =>
      isDark ? Colors.orangeAccent : Colors.orangeAccent;

  static Color shadow(bool isDark) =>
      Colors.black.withOpacity(isDark ? 0.2 : 0.1);
}

/// テキストスタイル
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

/// SkillsCard 専用設定
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
  static Color background(bool isDark) =>
      isDark ? Colors.grey[850]! : Colors.white;

  static Color cardColor(bool isDark) =>
      isDark ? Colors.grey[850]! : Colors.white;

  /// グラフ色セット
  static const List<Color> chartColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.red,
    Colors.purple,
    Colors.teal,
  ];

  /// Label / Value 用テキストサイズ
  static const double labelFontSize = 14;
  static const double valueFontSize = 12;

  static Color labelColor(bool isDark) => isDark ? Colors.white70 : Colors.black87;
  static Color valueColor(bool isDark) => isDark ? Colors.white54 : Colors.black54;

  /// 棒グラフ用追加設定
  static const double barWidth = 16.0;
  static const double barSpacing = 8.0;
  static const double barActiveOpacity = 0.8; // 追加
  static const double barInactiveOpacity = 0.3; // 追加
}