import 'package:flutter/material.dart';
import '../../../constants/app_texts.dart';
import '../../../widgets/app_loading_indicator.dart';

// ※現在どこからも参照されていない
// 色は lib/theme/app_colors.dart で管理
class ProjectsTabConfig {
  // tab labels
  static const tabs = [
    Tab(text: AppTexts.work),
    Tab(text: AppTexts.private),
  ];

  // spacing
  static const spacing = SizedBox(height: 16);

  // states
  static const loading = Center(child: AppLoadingIndicator());
  static const empty = Center(child: Text(AppTexts.noProjects));
}
