import 'package:flutter/material.dart';

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
  // Colors
  // =========================
  static const activeColor = Colors.blue;
  static const inactiveColor = Colors.transparent;

  static const activeTextColor = Colors.white;
  static const inactiveTextColor = Colors.black87;

  static const iconColor = Colors.grey;

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

  // =========================
  // Dark mode colors
  // =========================
  static const darkActiveColor = Colors.lightBlueAccent;
  static const darkInactiveColor = Colors.black26;
  static const darkActiveTextColor = Colors.black;
  static const darkInactiveTextColor = Colors.white70;
}