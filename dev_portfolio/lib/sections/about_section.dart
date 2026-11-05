// lib/sections/about_section.dart
import 'package:flutter/material.dart';
import 'config/about_section_config.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../models/profile.dart';
import '../utils/profile_store.dart';

/// About：自己紹介 ＋ 得意な領域 / 直近・過去の開発経験 / 強み / 開発スタイル ＋ 締めの一言
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

                // 得意な領域 / 直近・過去の開発経験 / 強み / 開発スタイル（YAML に書いたものだけ）
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
    // 直近 / 過去の開発経験（スキルシートの Excel から読み込んだときなど）
    if (profile.recent.isNotEmpty || profile.recentTech.isNotEmpty)
      (
        AboutContent.recentLabel,
        _ExperienceBody(text: profile.recent, tech: profile.recentTech),
      ),
    if (profile.past.isNotEmpty || profile.pastTech.isNotEmpty)
      (
        AboutContent.pastLabel,
        _ExperienceBody(text: profile.past, tech: profile.pastTech),
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

/// 開発経験の中身：「領域：説明」の行（領域を太字に）＋ 分類ごとの技術のタグ
class _ExperienceBody extends StatelessWidget {
  final String text;
  final Map<String, List<String>> tech;

  const _ExperienceBody({required this.text, required this.tech});

  static final _labelValue = RegExp(r'^([^：:]{1,30}?)([：:])(.*)$');

  @override
  Widget build(BuildContext context) {
    final body = AppStyles.aboutDescription(context);
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space6),
            child: Text.rich(
              switch (_labelValue.firstMatch(line.trim())) {
                final m? => TextSpan(children: [
                    TextSpan(
                      text: '${m.group(1)}${m.group(2)}',
                      style: body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: m.group(3)),
                  ]),
                null => TextSpan(text: line.trim()),
              },
              style: body,
            ),
          ),
        if (lines.isNotEmpty && tech.isNotEmpty) const SizedBox(height: AppSizes.space8),
        for (final e in tech.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.space8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.key, style: AppStyles.filterGroupLabel(context)),
                const SizedBox(height: AppSizes.space4),
                Wrap(
                  spacing: AppStyles.skillTagSpacing,
                  runSpacing: AppStyles.skillTagSpacing,
                  children: e.value
                      .map((t) => Container(
                            padding: AppStyles.skillTagPadding,
                            decoration: AppStyles.skillTag(context),
                            child: Text(t, style: AppStyles.skillTagText(context)),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
