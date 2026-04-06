import 'package:flutter/material.dart';

class ProjectsHeaderConfig {
  // text
  static const title = 'Projects';
  static const toggleLabel = 'Collection View';

  // styles
  static TextStyle titleStyle(bool isDark) => TextStyle(
        fontSize: 28,
        color: textColor(isDark),
      );

  static TextStyle labelStyle(bool isDark) =>
      TextStyle(color: textColor(isDark));

  // colors
  static Color textColor(bool isDark) =>
      isDark ? Colors.white : Colors.black;
}