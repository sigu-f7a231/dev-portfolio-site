import 'package:flutter/material.dart';

class ProjectsTabConfig {
  // tab labels
  static const tabs = [
    Tab(text: 'Work'),
    Tab(text: 'Private'),
  ];

  // colors
  static const activeColor = Colors.orangeAccent;

  static Color unselectedColor(bool isDark) =>
      isDark ? Colors.white : Colors.white;

  // spacing
  static const spacing = SizedBox(height: 16);

  // states
  static const loading = Center(child: CircularProgressIndicator());
  static const empty = Center(child: Text('No projects'));
}