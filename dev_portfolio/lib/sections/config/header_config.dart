import 'package:flutter/material.dart';

// 色は lib/theme/app_colors.dart（headerBackground / headerForeground）で管理
class HeaderConfig {
  // ブレークポイント
  static const double mobileBreakpoint = 600;

  // Desktop 用
  static const EdgeInsets desktopPadding = EdgeInsets.symmetric(horizontal: 40, vertical: 20);
}
