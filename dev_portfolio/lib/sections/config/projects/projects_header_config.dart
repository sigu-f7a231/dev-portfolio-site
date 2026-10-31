// lib/sections/config/projects/projects_header_config.dart
import 'package:flutter/material.dart';
import '../../../constants/app_sizes.dart';

/// Projects のヘッダー（タイトル）
/// 色は lib/theme/app_colors.dart、文字の見た目は lib/theme/app_styles.dart で管理
class ProjectsWidgetsHeaderConfig {
  /// セクションタイトルの文字サイズ
  static const double titleFontSize = 22;

  /// セクションタイトルのパディング
  static const EdgeInsets titlePadding =
      EdgeInsets.symmetric(vertical: AppSizes.space8);
}
