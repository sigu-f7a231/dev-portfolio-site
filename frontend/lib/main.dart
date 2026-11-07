// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'auth/auth_gate.dart';
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

  // Riverpod の状態（lib/state/providers.dart）をアプリ全体で使えるようにする
  // ログインを使うビルド（ENABLE_ACCOUNT）では、このタブで前にログインしていたら続けてログインする
  final container = ProviderContainer();
  if (accountRoutesEnabled) await container.read(authControllerProvider.notifier).restore();
  // ログインを使うビルドでは、ログインしていなければログインに移る（lib/router/app_router.dart の loginRedirect）
  final router = createAppRouter(gate: accountRoutesEnabled ? container.read(authGateProvider) : null);
  runApp(UncontrolledProviderScope(container: container, child: DevPortfolioApp(router: router)));

  // 描画が落ち着いたら、ローディング表示を消してよいと index.html に知らせる
  AppReady.notifyWhenSettled();
}

class DevPortfolioApp extends ConsumerWidget {
  const DevPortfolioApp({super.key, required this.router});

  /// 画面の切り替え（main で 1 つ作る）
  final GoRouter router;

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
      routerConfig: router,
      // 対応する最小の幅（320px）より狭い画面では、その幅のレイアウトを縮小して表示する
      builder: (context, child) => MinWidthScaler(child: child ?? const SizedBox()),
    );
  }
}
