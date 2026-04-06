// lib/sections/projects/config/projects_tab_config.dart
import 'package:flutter/material.dart';

class ProjectsTabConfig {
  // Tabs
  static const tabs = [
    Tab(text: 'Work'),
    Tab(text: 'Private'),
  ];

  // Colors
  static const activeColor = Colors.orangeAccent;

  static Color unselectedColor(bool isDark) =>
      isDark ? Colors.white : Colors.white;

  // Spacing
  static const spacing = SizedBox(height: 16);

  // States
  static const loading = Center(child: CircularProgressIndicator());

  static const empty = Center(child: Text('No projects'));
}