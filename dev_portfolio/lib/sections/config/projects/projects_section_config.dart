// lib/sections/projects/config/projects_section_config.dart
import 'package:flutter/material.dart';

class ProjectsSectionConfig {
  // 背景色
  static Color backgroundColor(bool isDark) => isDark ? Colors.black : Colors.indigo;

  // ヘッダーテキスト色
  static Color textColor(bool isDark) => Colors.white;

  // パディング
  static const EdgeInsets padding = EdgeInsets.all(24);

  // ヘッダー-タブ間の高さ
  static const SizedBox headerSpacing = SizedBox(height: 16);
}