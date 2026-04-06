// lib/sections/skills/config/skills_tabs_config.dart
import 'package:flutter/material.dart';

/// SkillsTabs 全体の設定
class SkillsTabsConfig {
  /// メインタブ名（Work / Private）
  static const List<String> mainTabs = ['Work', 'Private'];

  /// TabBar 用カラー
  static Color labelColor(bool isDark) => Colors.orangeAccent;
  static Color unselectedLabelColor(bool isDark) => isDark ? Colors.white70 : Colors.black54;
  static Color indicatorColor(bool isDark) => Colors.orangeAccent;

  /// TabBar とコンテンツ間のスペース
  static const double spacingBetweenTabBarAndContent = 16.0;

  /// カードサイズ（Chart を包む SizedBox）
  static const double cardWidth = 1000.0;
  static const double cardHeight = 500.0;
}