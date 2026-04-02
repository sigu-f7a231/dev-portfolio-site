import 'package:flutter/material.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 現在のテーマを取得
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[900] : Colors.teal[200];
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
      color: bgColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // セクションタイトル
          Text(
            'About Me',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 40),

          // 1. 自己紹介
          Text(
            '自己紹介: 名前・職種・簡単な経歴紹介',
            style: TextStyle(fontSize: 20, color: textColor),
          ),
          const SizedBox(height: 20),

          // 2. 得意な開発領域
          Text(
            '得意な開発領域: Web / モバイル / Flutter / Dart',
            style: TextStyle(fontSize: 20, color: textColor),
          ),
          const SizedBox(height: 20),

          // 3. 強み・スキル
          Text(
            '強み・スキル: チーム開発、テスト、UI改善など',
            style: TextStyle(fontSize: 20, color: textColor),
          ),
          const SizedBox(height: 20),

          // 4. 開発スタイル・価値観
          Text(
            '開発スタイル・価値観: コード品質、スクラム経験、レスポンシブ対応',
            style: TextStyle(fontSize: 20, color: textColor),
          ),
          const SizedBox(height: 20),

          // 5. 締めの一言
          Text(
            'ユーザー視点での開発を常に心がけています。',
            style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic, color: textColor),
          ),
        ],
      ),
    );
  }
}