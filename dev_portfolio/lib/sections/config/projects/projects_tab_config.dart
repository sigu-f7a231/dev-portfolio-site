// lib/sections/config/projects/projects_tab_config.dart
import 'package:flutter/material.dart';
import '../../../constants/app_texts.dart';
import '../../../widgets/app_loading_indicator.dart';

// ※現在どこからも参照されていない（Work/Private 切替は ProjectsTabView の SegmentedButton）
// 色は lib/theme/app_colors.dart で管理
class ProjectsTabConfig {
  // Tabs
  static const tabs = [
    Tab(text: AppTexts.work),
    Tab(text: AppTexts.private),
  ];

  // Spacing
  static const spacing = SizedBox(height: 16);

  // States
  static const loading = Center(child: AppLoadingIndicator());
  static const empty = Center(child: Text(AppTexts.noProjects));
}
