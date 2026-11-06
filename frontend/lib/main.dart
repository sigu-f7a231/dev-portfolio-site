// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/app_router.dart';
import 'state/providers.dart';
import 'theme/app_theme.dart';
import 'constants/app_texts.dart';
import 'utils/app_ready.dart';
import 'widgets/min_width_scaler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 起動時のローディング表示（web/index.html）の間に、最初の表示に使うデータを読み込んでおく
  await AppReady.preload();

  // ProviderScope：Riverpod の状態（lib/state/providers.dart）をアプリ全体で使えるようにする
  runApp(const ProviderScope(child: DevPortfolioApp()));

  // 描画が落ち着いたら、ローディング表示を消してよいと index.html に知らせる
  AppReady.notifyWhenSettled();
}

class DevPortfolioApp extends ConsumerWidget {
  const DevPortfolioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // テーマモードは themeModeProvider（Riverpod）が持ち、変わると MaterialApp ごと再構築される
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppTexts.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // 画面の URL（lib/router/app_router.dart。/・/login・/me・/me/edit）
      routerConfig: appRouter,
      // 対応する最小の幅（320px）より狭い画面では、その幅のレイアウトを縮小して表示する
      builder: (context, child) => MinWidthScaler(child: child ?? const SizedBox()),
    );
  }
}
