// lib/router/app_router.dart
//
// 画面の URL（go_router）
// - /            … 公開ページ（Home・About・Skills・Projects）
// - /login       … ログイン（準備中の空の画面）
// - /me          … マイページ（準備中）
// - /me/edit     … 編集（準備中）
// - ログイン・マイページの URL は、ビルドの設定 --dart-define=ENABLE_ACCOUNT=true を付けたときだけ使える
//   （develop に push すると公開ページになるため、ふだんのビルドでは出さない。開くと / に移る）
// - URL は # 付き（Flutter Web の既定）のまま。GitHub Pages は # のない URL をすべて index.html に向けられないため
// - ない URL を開いたら / に移る
import 'package:go_router/go_router.dart';

import '../constants/app_texts.dart';
import '../pages/home_page.dart';
import '../pages/placeholder_page.dart';

/// URL の一覧
class AppRoutes {
  AppRoutes._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  /// 公開ページ（Home・About・Skills・Projects）
  static const String home = '/';

  /// ログイン（画面設計の A-01）
  static const String login = '/login';

  /// マイページ（M-01）
  static const String myPage = '/me';

  /// 編集（M-02〜M-06。/me の下）
  static const String edit = '/me/edit';
}

/// ログイン・マイページの URL を使うか（--dart-define=ENABLE_ACCOUNT=true のときだけ）
const bool accountRoutesEnabled = bool.fromEnvironment('ENABLE_ACCOUNT');

/// 画面の切り替え（アプリ全体で 1 つ。テストでは毎回作る）
GoRouter createAppRouter({
  String initialLocation = AppRoutes.home,
  bool enableAccount = accountRoutesEnabled,
}) =>
    GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
        if (enableAccount) ...[
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const PlaceholderPage(title: RouteTexts.login, screenId: 'A-01'),
          ),
          GoRoute(
            path: AppRoutes.myPage,
            builder: (context, state) => const PlaceholderPage(title: RouteTexts.myPage, screenId: 'M-01'),
            routes: [
              GoRoute(
                path: 'edit', // /me/edit
                builder: (context, state) => const PlaceholderPage(title: RouteTexts.edit, screenId: 'M-02〜M-06'),
              ),
            ],
          ),
        ],
      ],
      // ない URL（ENABLE_ACCOUNT なしのログイン・マイページも）は / に移る（「見つかりません」の画面は段階 5 で作る）
      onException: (context, state, router) => router.go(AppRoutes.home),
    );

/// main.dart が使う
final GoRouter appRouter = createAppRouter();
