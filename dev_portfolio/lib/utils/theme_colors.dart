// lib/utils/colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // ProjectsSection 背景色
  static Color background(bool isDark) => isDark ? Colors.black87 : Colors.white;

  // ProjectsTabView タブの文字色
  static Color tabLabel(bool isDark) => isDark ? Colors.white : Colors.black87;
  static Color tabUnselected(bool isDark) => isDark ? Colors.white54 : Colors.black45;

  // ProjectCollectionView / ProjectListUI カード色
  static Color card(bool isDark) => isDark ? Colors.grey[850]! : Colors.white;

  // Project skill ボタン色
  static Color skillButton(bool isDark) => isDark ? Colors.blueGrey : Colors.blue[100]!;

  // ProjectsPaginationUI のボタン色
  static Color paginationButton(bool isDark) => isDark ? Colors.grey[700]! : Colors.grey[300]!;

  // 文字色などは必要に応じて追加
  static Color text(bool isDark) => isDark ? Colors.white : Colors.black87;
}