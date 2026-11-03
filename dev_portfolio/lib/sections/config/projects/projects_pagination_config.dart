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

  /// ページ番号ボタンの大きさ（丸いボタン）
  static const pageButtonSize = 40.0;

  /// 前へ / 次へボタン 1 個ぶんの幅（IconButton の既定サイズ）
  static const navButtonWidth = 48.0;

  /// 番号ボタンを並べられる数がこれ未満なら「‹ 3 / 10 ›」の簡易表示にする
  static const minNumberedButtons = 5;

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
