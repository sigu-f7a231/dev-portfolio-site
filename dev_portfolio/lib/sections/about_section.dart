// lib/sections/about_section.dart
import 'package:flutter/material.dart';
import 'config/about_section_config.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';

/// About：自己紹介 ＋ 得意な領域 / 強み / 開発スタイル ＋ 締めの一言
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
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
                  AboutContent.intro,
                  style: AppStyles.aboutLead(
                      context, AboutSectionConfig.introFontSize),
                ),
                AboutSectionConfig.introSpacing,

                // 得意な領域 / 強み / 開発スタイル
                _AboutRow(
                  isWide: isWide,
                  label: AboutContent.domainsLabel,
                  child: Wrap(
                    spacing: AppStyles.skillTagSpacing,
                    runSpacing: AppStyles.skillTagSpacing,
                    children: AboutContent.domains
                        .map((d) => Container(
                              padding: AppStyles.skillTagPadding,
                              decoration: AppStyles.skillTag(context),
                              child: Text(d, style: AppStyles.skillTagText(context)),
                            ))
                        .toList(),
                  ),
                ),
                _AboutRow(
                  isWide: isWide,
                  label: AboutContent.strengthsLabel,
                  child: Text(AboutContent.strengths,
                      style: AppStyles.aboutDescription(context)),
                ),
                _AboutRow(
                  isWide: isWide,
                  label: AboutContent.styleLabel,
                  isLast: true,
                  child: Text(AboutContent.style,
                      style: AppStyles.aboutDescription(context)),
                ),
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
                        child: Text(AboutContent.closing,
                            style: AppStyles.aboutClosing(context)),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
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
