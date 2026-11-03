// lib/sections/about_section.dart
import 'package:flutter/material.dart';
import 'config/about_section_config.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../models/profile.dart';
import '../utils/profile_store.dart';

/// About：自己紹介 ＋ 得意な領域 / 強み / 開発スタイル ＋ 締めの一言
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Profile?>(
      valueListenable: ProfileStore.instance,
      builder: (context, profile, _) => _build(context, profile ?? Profile.empty),
    );
  }

  Widget _build(BuildContext context, Profile profile) {
    return Container(
      width: double.infinity,
      padding: AboutSectionConfig.padding,
      color: context.colors.aboutBackground,
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: AboutSectionConfig.maxContentWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= AboutSectionConfig.wideBreakpoint;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AboutContent.heading,
                  style: AppStyles.aboutHeading(
                      context, AboutSectionConfig.headingFontSize),
                ),
                AboutSectionConfig.headingSpacing,

                // 自己紹介
                Text(
                  profile.intro,
                  style: AppStyles.aboutLead(
                      context, AboutSectionConfig.introFontSize),
                ),
                AboutSectionConfig.introSpacing,

                // 得意な領域 / 強み / 開発スタイル（YAML に書いたものだけ）
                ..._rows(context, profile, isWide),
                if (profile.closing.isNotEmpty) ...[
                AboutSectionConfig.closingSpacing,

                // 締めの一言（左に縦線）
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: AboutSectionConfig.closingBarWidth,
                        decoration: BoxDecoration(
                          color: context.colors.aboutAccent,
                          borderRadius: BorderRadius.circular(
                              AboutSectionConfig.closingBarWidth),
                        ),
                      ),
                      const SizedBox(width: AboutSectionConfig.closingBarGap),
                      Expanded(
                        child: Text(profile.closing,
                            style: AppStyles.aboutClosing(context)),
                      ),
                    ],
                  ),
                ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 定義リストの行（空の項目は出さない。最後の行だけ下にも線を引く）
List<Widget> _rows(BuildContext context, Profile profile, bool isWide) {
  final items = <(String, Widget)>[
    if (profile.domains.isNotEmpty)
      (
        AboutContent.domainsLabel,
        Wrap(
          spacing: AppStyles.skillTagSpacing,
          runSpacing: AppStyles.skillTagSpacing,
          children: profile.domains
              .map((d) => Container(
                    padding: AppStyles.skillTagPadding,
                    decoration: AppStyles.skillTag(context),
                    child: Text(d, style: AppStyles.skillTagText(context)),
                  ))
              .toList(),
        ),
      ),
    if (profile.strengths.isNotEmpty)
      (
        AboutContent.strengthsLabel,
        Text(profile.strengths, style: AppStyles.aboutDescription(context)),
      ),
    if (profile.style.isNotEmpty)
      (
        AboutContent.styleLabel,
        Text(profile.style, style: AppStyles.aboutDescription(context)),
      ),
  ];

  return [
    for (var i = 0; i < items.length; i++)
      _AboutRow(
        isWide: isWide,
        label: items[i].$1,
        isLast: i == items.length - 1,
        child: items[i].$2,
      ),
  ];
}

/// 「見出し｜説明」の 1 行。上下を細い線で区切る（狭い画面では縦に積む）
class _AboutRow extends StatelessWidget {
  final bool isWide;
  final String label;
  final Widget child;
  final bool isLast;

  const _AboutRow({
    required this.isWide,
    required this.label,
    required this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final divider = BorderSide(color: context.colors.aboutDivider);
    final term = Text(label, style: AppStyles.aboutTerm(context));

    return Container(
      padding: AboutSectionConfig.rowPadding,
      decoration: BoxDecoration(
        border: Border(top: divider, bottom: isLast ? divider : BorderSide.none),
      ),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: AboutSectionConfig.termWidth, child: term),
                Expanded(child: child),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [term, const SizedBox(height: AppSizes.space8), child],
            ),
    );
  }
}
