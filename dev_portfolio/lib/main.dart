// lib/main.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';
import 'constants/app_texts.dart';
import 'utils/app_ready.dart';
import 'widgets/min_width_scaler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 起動時のローディング表示（web/index.html）の間に、最初の表示に使うデータを読み込んでおく
  await AppReady.preload();

  runApp(const DevPortfolioApp());

  // 描画が落ち着いたら、ローディング表示を消してよいと index.html に知らせる
  AppReady.notifyWhenSettled();
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
          // 対応する最小の幅（320px）より狭い画面では、その幅のレイアウトを縮小して表示する
          builder: (context, child) => MinWidthScaler(child: child ?? const SizedBox()),
        );
      },
    );
  }
}
