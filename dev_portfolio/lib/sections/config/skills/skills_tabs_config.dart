// lib/sections/config/skills/skills_tabs_config.dart
// 色は lib/theme/app_colors.dart（accent / textSecondary）で管理
import '../../../constants/app_texts.dart';

/// SkillsTabs 全体の設定
class SkillsTabsConfig {
  /// メインタブ名（Work / Private）
  static const List<String> mainTabs = [AppTexts.work, AppTexts.private];

  /// TabBar とコンテンツ間のスペース
  static const double spacingBetweenTabBarAndContent = 16.0;

  /// カードサイズ（Chart を包む SizedBox）
  static const double cardWidth = 1000.0;
  static const double cardHeight = 500.0;
}
