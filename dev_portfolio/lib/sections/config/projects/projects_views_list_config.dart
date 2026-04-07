import 'package:flutter/material.dart';

class ProjectsListConfig {
  // =========================
  // 既存設定（変更なし）
  // =========================
  static const separator = SizedBox(height: 12);

  static Color cardColor(bool isDark) =>
      isDark ? Colors.grey[850]! : Colors.white;

  static Color titleColor(bool isDark) => isDark ? Colors.white : Colors.black;
  static Color subtitleColor(bool isDark) => isDark ? Colors.white70 : Colors.black54;

  static TextStyle titleStyle(bool isDark) => TextStyle(color: titleColor(isDark));
  static TextStyle subtitleStyle(bool isDark) => TextStyle(color: subtitleColor(isDark));

  static const loading = Center(child: CircularProgressIndicator());
  static const empty = Center(child: Text('No projects'));

  // =========================
  // 🔽 UI用ハードコーディング値
  // =========================
  static const scheduleIconSize = 14.0;
  static const periodFontSize = 12.0;
  static const periodIconSpacing = 4.0;

  static const ongoingTagFontSize = 10.0;
  static const ongoingTagPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 2);
  static const ongoingTagMargin = EdgeInsets.only(top: 6);
  static const ongoingTagColor = Colors.green;
  static const ongoingTagTextColor = Colors.white;
  static const ongoingTagBorderRadius = 4.0; // 追加

  static const smallSpacing = SizedBox(height: 6);

  // サブテキスト（期間）のカラー
  static Color periodTextColor(bool isDark) => isDark ? Colors.white70 : Colors.black54;

  // =========================
  // 🔽 モーダル用追加設定
  // =========================
  static const modalPadding = EdgeInsets.all(16);
  static const modalMaxHeight = 600.0;

  static const fieldPadding = EdgeInsets.symmetric(vertical: 6);

  static TextStyle fieldLabelStyle(double fontSize) => TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey,
        fontSize: fontSize,
      );

  static TextStyle fieldValueStyle(bool isBold) => TextStyle(
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
        color: Colors.black87,
      );

  static const closeButtonSize = 24.0;
  static const closeButtonColor = Colors.black54;

  static const verticalSpacingSmall = SizedBox(height: 12);

  static ButtonStyle linkButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );

  // =========================
  // 🔽 コレクション用（Gridなど）既存追記
  // =========================
  static const cardPadding = EdgeInsets.all(8);

  static Color collectionCardColor(bool isDark) =>
      isDark ? Colors.grey.shade900 : Colors.white;

  static Color collectionTitleColor(bool isDark) =>
      isDark ? Colors.white : Colors.black;

  static Color collectionDescriptionColor(bool isDark) =>
      isDark ? Colors.white70 : Colors.black54;

  static Color collectionPeriodColor(bool isDark) =>
      isDark ? Colors.white54 : Colors.black45;

  static TextStyle collectionTitleStyle(bool isDark) => TextStyle(
        fontWeight: FontWeight.bold,
        color: collectionTitleColor(isDark),
      );

  static TextStyle collectionDescriptionStyle(bool isDark) =>
      TextStyle(color: collectionDescriptionColor(isDark));

  static TextStyle collectionPeriodStyle(bool isDark) => TextStyle(
        fontSize: 12,
        color: collectionPeriodColor(isDark),
      );

  static const verticalSpacingVerySmall = SizedBox(height: 4);

  // =========================
  // 🔽 Card / Container用 BorderRadius
  // =========================
  static const cardBorderRadius = 4.0;
}