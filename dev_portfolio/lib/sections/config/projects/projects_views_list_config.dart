import 'package:flutter/material.dart';

class ProjectsListConfig {
  // spacing
  static const separator = SizedBox(height: 12);

  // colors
  static Color cardColor(bool isDark) =>
      isDark ? Colors.grey[850]! : Colors.white;

  static Color titleColor(bool isDark) =>
      isDark ? Colors.white : Colors.black;

  static Color subtitleColor(bool isDark) =>
      isDark ? Colors.white70 : Colors.black54;

  // text styles
  static TextStyle titleStyle(bool isDark) =>
      TextStyle(color: titleColor(isDark));

  static TextStyle subtitleStyle(bool isDark) =>
      TextStyle(color: subtitleColor(isDark));

  // states
  static const loading = Center(child: CircularProgressIndicator());

  static const empty = Center(child: Text('No projects'));
}