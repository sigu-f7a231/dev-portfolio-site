// lib/sections/hero_section.dart
import 'package:flutter/material.dart';
import 'config/hero_section_config.dart';
import '../theme/app_theme.dart';
import '../theme/app_styles.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../models/profile.dart';
import '../utils/profile_store.dart';

/// Home：名前・職種・紹介文 ＋ プロフィールのカード（中身はプロフィール YAML から）
class HeroSection extends StatelessWidget {
  final VoidCallback? onSkillsPressed;
  final VoidCallback? onProjectsPressed;

  const HeroSection({
    super.key,
    this.onSkillsPressed,
    this.onProjectsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Profile?>(
      valueListenable: ProfileStore.instance,
      builder: (context, profile, _) => _build(context, profile ?? Profile.empty),
    );
  }

  Widget _build(BuildContext context, Profile profile) {
    final hasCard = profile.card.isNotEmpty;
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: HeroSectionConfig.height(context)),
      color: context.colors.heroBackground,
      padding: HeroSectionConfig.padding,
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: HeroSectionConfig.maxContentWidth),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= HeroSectionConfig.wideBreakpoint;
            final showCode = width >= HeroSectionConfig.codeCardBreakpoint;

            final intro = _Intro(
              profile: profile,
              isWide: isWide,
              onSkillsPressed: onSkillsPressed,
              onProjectsPressed: onProjectsPressed,
            );

            if (isWide && hasCard) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: intro),
                  const SizedBox(width: AppSizes.space48),
                  SizedBox(
                    width: HeroSectionConfig.codeCardWidth,
                    child: _ProfileYaml(card: profile.card),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                intro,
                if (showCode && hasCard && !isWide) ...[
                  const SizedBox(height: AppSizes.space40),
                  _ProfileYaml(card: profile.card),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 左側：名前・職種・紹介文・ボタン
class _Intro extends StatelessWidget {
  final Profile profile;
  final bool isWide;
  final VoidCallback? onSkillsPressed;
  final VoidCallback? onProjectsPressed;

  const _Intro({
    required this.profile,
    required this.isWide,
    this.onSkillsPressed,
    this.onProjectsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          profile.role,
          style: AppStyles.heroRole(context, HeroSectionConfig.roleFontSize),
        ),
        const SizedBox(height: AppSizes.space12),
        Text(
          profile.name,
          style: AppStyles.heroName(
            context,
            isWide
                ? HeroSectionConfig.nameFontSizeWide
                : HeroSectionConfig.nameFontSizeNarrow,
          ),
        ),
        const SizedBox(height: AppSizes.space24),
        ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: HeroSectionConfig.taglineMaxWidth),
          child: Text(
            profile.tagline,
            style: AppStyles.heroTagline(
                context, HeroSectionConfig.taglineFontSize),
          ),
        ),
        const SizedBox(height: AppSizes.space36),
        Wrap(
          spacing: AppSizes.space12,
          runSpacing: AppSizes.space12,
          children: [
            FilledButton(
              onPressed: onSkillsPressed,
              style: AppStyles.heroPrimaryButton(context),
              child: const Text(HeroContent.skillsButtonLabel),
            ),
            OutlinedButton(
              onPressed: onProjectsPressed,
              style: AppStyles.heroSecondaryButton(context),
              child: const Text(HeroContent.projectsButtonLabel),
            ),
          ],
        ),
      ],
    );
  }
}

/// 右側：プロフィールを YAML 風に表示するカード
/// （このサイトのデータが YAML で書かれていることにちなんだ見せ方）
class _ProfileYaml extends StatelessWidget {
  final Map<String, Object> card;

  const _ProfileYaml({required this.card});

  @override
  Widget build(BuildContext context) {
    final keyStyle = AppStyles.heroCode(context, isKey: true);
    final valueStyle = AppStyles.heroCode(context);

    final lines = <InlineSpan>[];
    card.forEach((key, value) {
      lines.add(TextSpan(text: '$key:', style: keyStyle));
      if (value is List) {
        lines.add(const TextSpan(text: '\n'));
        for (final item in value) {
          lines.add(TextSpan(text: '  - $item\n', style: valueStyle));
        }
      } else {
        lines.add(TextSpan(text: ' $value\n', style: valueStyle));
      }
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.space24),
      decoration: AppStyles.heroCodeCard(context),
      child: SelectableText.rich(
        TextSpan(children: lines),
      ),
    );
  }
}
