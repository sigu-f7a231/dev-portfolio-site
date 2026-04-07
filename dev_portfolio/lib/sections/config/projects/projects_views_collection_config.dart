// dev_portfolio/lib/sections/config/projects/projects_views_collection_config.dart
import 'package:flutter/material.dart';

class ProjectsCollectionConfig {
  // Layout
  static const padding = EdgeInsets.all(3);
  static const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 4,
    crossAxisSpacing: 4,
    mainAxisSpacing: 4,
  );

  // Colors
  static Color cardColor(bool isDark) => isDark ? Colors.grey.shade900 : Colors.white;
  static Color titleColor(bool isDark) => isDark ? Colors.white : Colors.black;
  static Color descriptionColor(bool isDark) => isDark ? Colors.white70 : Colors.black54;
  static Color periodColor(bool isDark) => isDark ? Colors.white54 : Colors.black45;

  // TextStyles
  static TextStyle titleStyle(bool isDark) => TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: titleColor(isDark),
      );

  static TextStyle descriptionStyle(bool isDark) =>
      TextStyle(fontSize: 14, color: descriptionColor(isDark));

  static TextStyle periodStyle(bool isDark) =>
      TextStyle(fontSize: 12, color: periodColor(isDark));

  // Card padding / spacing
  static const cardPadding = EdgeInsets.all(4);
  static const verticalSpacingSmall = SizedBox(height: 2);

  // =========================
  // 🔹 スキルボタン用
  // =========================
  static Color skillButtonColor(bool isDark) =>
      isDark ? Colors.blueGrey.shade700 : Colors.blue.shade100;

  static Color skillButtonTextColor(bool isDark) =>
      isDark ? Colors.white : Colors.black87;

  static const skillButtonPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 2);
  static const skillButtonBorderRadius = 12.0;
  static const skillButtonFontSize = 12.0;
  static const skillButtonFontWeight = FontWeight.bold;
  static const skillButtonSpacing = 4.0;
  static const skillButtonRunSpacing = 2.0;
}