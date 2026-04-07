// lib/sections/config/projects/projects_widgets_header_config.dart
import 'package:flutter/material.dart';

/// Projects のヘッダー用ウィジェット設定
class ProjectsWidgetsHeaderConfig {
  /// セクションタイトル文字スタイル
  static TextStyle titleStyle(bool isDark) => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black,
      );

  /// セクションタイトルの上下パディング
  static const EdgeInsets titlePadding =
      EdgeInsets.symmetric(vertical: 8, horizontal: 16);

  /// List / Collection 切替スイッチのアクティブ色
  static const Color switchActiveColor = Colors.blueAccent;

  /// スイッチの非アクティブ色（ダーク/ライト）
  static Color switchInactiveColor(bool isDark) =>
      isDark ? Colors.white10 : Colors.black12;

  /// スイッチ内のテキスト色（アクティブ）
  static Color switchTextActiveColor(bool isDark) =>
      isDark ? Colors.black : Colors.black87;

  /// スイッチ内のテキスト色（非アクティブ）
  static Color switchTextInactiveColor(bool isDark) =>
      isDark ? Colors.white60 : Colors.black45;

  /// スイッチボタンの最小幅
  static const double switchMinWidth = 70;

  /// スイッチボタンのパディング
  static const EdgeInsets switchPadding =
      EdgeInsets.symmetric(horizontal: 14, vertical: 8);

  /// スイッチボタンの角丸
  static const double switchBorderRadius = 8.0;

  /// スイッチ左右間の間隔
  static const double switchSpacing = 8.0;
}