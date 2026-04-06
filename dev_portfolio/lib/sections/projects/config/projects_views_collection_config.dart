import 'package:flutter/material.dart';

class ProjectsCollectionConfig {
  // Layout
  static const padding = EdgeInsets.all(8);

  static const gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 1.5,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  );

  // Colors
  static Color cardColor(bool isDark) =>
      isDark ? Colors.grey.shade900 : Colors.white;

  static Color titleColor(bool isDark) =>
      isDark ? Colors.white : Colors.black;

  static Color descriptionColor(bool isDark) =>
      isDark ? Colors.white70 : Colors.black54;

  static Color periodColor(bool isDark) =>
      isDark ? Colors.white54 : Colors.black45;

  // TextStyles
  static TextStyle titleStyle(bool isDark) => TextStyle(
        fontWeight: FontWeight.bold,
        color: titleColor(isDark),
      );

  static TextStyle descriptionStyle(bool isDark) =>
      TextStyle(color: descriptionColor(isDark));

  static TextStyle periodStyle(bool isDark) => TextStyle(
        fontSize: 12,
        color: periodColor(isDark),
      );

  static const cardPadding = EdgeInsets.all(8);
  static const verticalSpacingSmall = SizedBox(height: 4);
}