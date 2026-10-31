// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';
import 'constants/app_texts.dart';

void main() {
  runApp(const DevPortfolioApp());
}

class DevPortfolioApp extends StatelessWidget {
  const DevPortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    // テーマモードは ThemeController が保持し、変わると MaterialApp ごと再構築される
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppTexts.appTitle,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}
