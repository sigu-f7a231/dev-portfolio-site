// lib/sections/about_section.dart
import 'package:flutter/material.dart';
import 'config/about_section_config.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: AboutSectionConfig.padding,
      color: AboutSectionConfig.backgroundColor(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションタイトル
          Text(
            'About Me',
            style: TextStyle(
              fontSize: AboutSectionConfig.titleFontSize,
              fontWeight: AboutSectionConfig.titleFontWeight,
              color: AboutSectionConfig.textColor(isDark),
            ),
          ),
          AboutSectionConfig.sectionSpacing,

          // 1. 自己紹介
          Text(
            '自己紹介: 名前・職種・簡単な経歴紹介',
            style: TextStyle(
              fontSize: AboutSectionConfig.bodyFontSize,
              color: AboutSectionConfig.textColor(isDark),
              fontStyle: AboutSectionConfig.bodyFontStyleNormal,
            ),
          ),
          AboutSectionConfig.textSpacing,

          // 2. 得意な開発領域
          Text(
            '得意な開発領域: Web / モバイル / Flutter / Dart',
            style: TextStyle(
              fontSize: AboutSectionConfig.bodyFontSize,
              color: AboutSectionConfig.textColor(isDark),
            ),
          ),
          AboutSectionConfig.textSpacing,

          // 3. 強み・スキル
          Text(
            '強み・スキル: チーム開発、テスト、UI改善など',
            style: TextStyle(
              fontSize: AboutSectionConfig.bodyFontSize,
              color: AboutSectionConfig.textColor(isDark),
            ),
          ),
          AboutSectionConfig.textSpacing,

          // 4. 開発スタイル・価値観
          Text(
            '開発スタイル・価値観: コード品質、スクラム経験、レスポンシブ対応',
            style: TextStyle(
              fontSize: AboutSectionConfig.bodyFontSize,
              color: AboutSectionConfig.textColor(isDark),
            ),
          ),
          AboutSectionConfig.textSpacing,

          // 5. 締めの一言
          Text(
            'ユーザー視点での開発を常に心がけています。',
            style: TextStyle(
              fontSize: AboutSectionConfig.bodyFontSize,
              color: AboutSectionConfig.textColor(isDark),
              fontStyle: AboutSectionConfig.bodyFontStyleItalic,
            ),
          ),
        ],
      ),
    );
  }
}