import 'package:flutter/material.dart';

// 色は lib/theme/app_colors.dart（pagination*）で管理
class ProjectsPaginationConfig {
  // =========================
  // Layout
  // =========================
  static const containerPadding = EdgeInsets.symmetric(vertical: 12);

  static const pagePadding =
      EdgeInsets.symmetric(horizontal: 10, vertical: 6);

  static const pageMargin =
      EdgeInsets.symmetric(horizontal: 4);

  static const borderRadius = 6.0;

  // =========================
  // Typography
  // =========================
  static const fontSize = 14.0;

  // =========================
  // Icon
  // =========================
  static const iconSize = 20.0;

  // =========================
  // Pagination behavior
  // =========================
  static const itemsPerPage = 5; // 1ページの表示件数
}
