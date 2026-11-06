// lib/sections/header/header_parts.dart
//
// ヘッダーの部品（M3）
import 'package:flutter/material.dart';
import '../config/header_config.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_styles.dart';
import '../../constants/app_texts.dart';

/// ナビの行き先（ヘッダー・Drawer で共通）
class NavDestination {
  final String section;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const NavDestination(this.section, this.label, this.icon, this.selectedIcon);

  static const List<NavDestination> all = [
    NavDestination('home', AppTexts.navHome, Icons.home_outlined, Icons.home),
    NavDestination('about', AppTexts.navAbout, Icons.person_outline, Icons.person),
    NavDestination('skills', AppTexts.navSkills, Icons.bar_chart_outlined, Icons.bar_chart),
    NavDestination('projects', AppTexts.navProjects, Icons.work_outline, Icons.work),
  ];
}

/// ナビボタン：選択中は丸いインジケーター（secondaryContainer）＋塗りアイコン
class HeaderNavButton extends StatelessWidget {
  final NavDestination destination;
  final bool selected;
  final bool showLabel;
  final VoidCallback onPressed;

  const HeaderNavButton({
    super.key,
    required this.destination,
    required this.selected,
    required this.onPressed,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      selected ? destination.selectedIcon : destination.icon,
      size: HeaderConfig.navIconSize,
    );
    final style = AppStyles.navButton(context, selected: selected).copyWith(
      padding: WidgetStatePropertyAll(
        showLabel ? HeaderConfig.navPadding : null,
      ),
    );

    final button = showLabel
        ? TextButton.icon(
            onPressed: onPressed,
            style: style,
            icon: icon,
            label: Text(destination.label),
          )
        : IconButton(
            onPressed: onPressed,
            style: style,
            tooltip: destination.label,
            icon: icon,
          );

    return Semantics(selected: selected, button: true, child: button);
  }
}

/// Work / Private の YAML アップロードボタン（M3 の Filled tonal ボタン）
/// 押したときの動き（[onPressed]）は呼び出し側のまま。見た目だけを揃える
class HeaderUploadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final bool showLabel;
  final VoidCallback onPressed;

  const HeaderUploadButton({
    super.key,
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showLabel) {
      return IconButton.filledTonal(
        icon: Icon(icon),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }
    return Tooltip(
      message: tooltip,
      child: FilledButton.tonalIcon(
        icon: Icon(icon, size: HeaderConfig.navIconSize),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }
}

/// ライト / ダークの切り替え（M3 の Switch：つまみに太陽 / 月のアイコン）
/// [compact] が true（スマホ）のときは、M3 のトグル式アイコンボタン（太陽 ⇄ 月）にする
class ThemeModeSwitch extends StatelessWidget {
  final bool compact;

  const ThemeModeSwitch({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    if (compact) {
      return IconButton(
        isSelected: isDark,
        tooltip: isDark ? AppTexts.toLightMode : AppTexts.toDarkMode,
        icon: const Icon(Icons.light_mode_outlined),
        selectedIcon: const Icon(Icons.dark_mode),
        onPressed: () => ThemeController.instance.toggle(!isDark),
      );
    }
    return Tooltip(
      message: isDark ? AppTexts.toLightMode : AppTexts.toDarkMode,
      child: Switch(
        value: isDark,
        onChanged: ThemeController.instance.toggle,
        thumbIcon: WidgetStateProperty.resolveWith(
          (states) => Icon(
            states.contains(WidgetState.selected)
                ? Icons.dark_mode
                : Icons.light_mode,
          ),
        ),
      ),
    );
  }
}
