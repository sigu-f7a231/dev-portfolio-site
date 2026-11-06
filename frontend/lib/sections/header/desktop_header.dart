import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/header_config.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_styles.dart';
import 'project_data_dialog.dart';
import 'download_menu.dart';
import 'header_parts.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';

class DesktopHeader extends StatelessWidget {
  final VoidCallback onHomePressed;
  final VoidCallback onAboutPressed;
  final VoidCallback onSkillsPressed;
  final VoidCallback onProjectsPressed;

  // 外部へのコールバックが不要な場合は削除可能ですが、
  // 保存後に画面の再描画などをトリガーしたい場合はオプショナルに残しておけます
  final VoidCallback? onYamlStateChanged;
  final ValueListenable<String> activeSection;

  const DesktopHeader({
    super.key,
    required this.onHomePressed,
    required this.onAboutPressed,
    required this.onSkillsPressed,
    required this.onProjectsPressed,
    this.onYamlStateChanged,
    required this.activeSection,
  });

  // ［データ］：Work / Private のプロジェクトの追加・更新（中身は project_data_dialog.dart）
  void _showDataDialog(BuildContext context) =>
      showProjectDataDialog(context, onSaved: onYamlStateChanged);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final go = <String, VoidCallback>{
      'home': onHomePressed,
      'about': onAboutPressed,
      'skills': onSkillsPressed,
      'projects': onProjectsPressed,
    };

    // M3 の Small top app bar：タイトル ＋ ナビ ／ アクション（アップロード・テーマ切替）
    return Material(
      color: colors.headerBackground,
      child: Container(
        height: HeaderConfig.desktopHeight,
        padding: HeaderConfig.desktopPadding,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.headerDivider)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showLabel = constraints.maxWidth >= HeaderConfig.navLabelBreakpoint;
            final showTitle = constraints.maxWidth >= HeaderConfig.titleBreakpoint;
            final showUploadLabel =
                constraints.maxWidth >= HeaderConfig.uploadLabelBreakpoint;
            return Row(
              children: [
                if (showTitle) ...[
                  Text(AppTexts.appTitle, style: AppStyles.headerTitle(context)),
                  const SizedBox(width: HeaderConfig.titleNavGap),
                ],

                // ナビ（表示中のセクションに丸いインジケーター）
                ValueListenableBuilder<String>(
                  valueListenable: activeSection,
                  builder: (context, active, _) => Row(
                    children: [
                      for (final d in NavDestination.all) ...[
                        HeaderNavButton(
                          destination: d,
                          selected: d.section == active,
                          showLabel: showLabel,
                          onPressed: go[d.section]!,
                        ),
                        const SizedBox(width: HeaderConfig.navGap),
                      ],
                    ],
                  ),
                ),
                const Spacer(),

                // アクション
                HeaderUploadButton(
                  icon: Icons.dataset_outlined,
                  label: DataTexts.button,
                  tooltip: DataTexts.buttonTooltip,
                  showLabel: showUploadLabel,
                  onPressed: () => _showDataDialog(context),
                ),
                const SizedBox(width: HeaderConfig.uploadGap),
                // スキルシート（Excel / PDF）のダウンロード
                HeaderDownloadButton(showLabel: showUploadLabel),
                VerticalDivider(
                  width: AppSizes.space24,
                  indent: HeaderConfig.actionsDividerIndent,
                  endIndent: HeaderConfig.actionsDividerIndent,
                  color: colors.headerDivider,
                ),
                const ThemeModeSwitch(),
              ],
            );
          },
        ),
      ),
    );
  }
}