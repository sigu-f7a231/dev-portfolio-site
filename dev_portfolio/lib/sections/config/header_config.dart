import 'package:flutter/material.dart';

class HeaderConfig {
  // ブレークポイント
  static const double mobileBreakpoint = 600;

  // Desktop 用
  static const EdgeInsets desktopPadding = EdgeInsets.symmetric(horizontal: 40, vertical: 20);

  // 背景色
  static Color backgroundColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.black87 : Colors.blueAccent;

  // 文字色
  static Color textColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.white;

  // Mobile 用（同じ値で統一可）
  static Color mobileBackgroundColor(BuildContext context) => backgroundColor(context);
  static Color mobileTextColor(BuildContext context) => textColor(context);
}