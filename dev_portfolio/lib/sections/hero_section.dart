import 'package:flutter/material.dart';
import 'config/hero_section_config.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: HeroSectionConfig.height(context),
      color: HeroSectionConfig.backgroundColor(isDark),
      child: const Center(
        child: Text(
          'Welcome to My Portfolio',
          textAlign: HeroSectionConfig.titleAlign,
          style: TextStyle(
            fontSize: HeroSectionConfig.titleFontSize,
            color: HeroSectionConfig.titleColor,
          ),
        ),
      ),
    );
  }
}