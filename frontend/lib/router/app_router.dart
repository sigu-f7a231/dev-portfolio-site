// lib/router/app_router.dart
//
// 画面の URL（go_router）
// - /            … 公開ページ（Home・About・Skills・Projects）
// - /login       … ログイン・登録（lib/pages/login_page.dart）
// - /me          … マイページ（lib/pages/my_page.dart。ログインしていなければログインへの案内）
// - /me/edit     … 編集（準備中の空の画面。段階 5-2）
// - ログイン・マイページの URL は、ビルドの設定 --dart-define=ENABLE_ACCOUNT=true を付けたときだけ使える
//   （develop に push すると公開ページになるため、ふだんのビルドでは出さない。開くと / に移る）
// - URL は # 付き（Flutter Web の既定）のまま。GitHub Pages は # のない URL をすべて index.html に向けられないため
// - ない URL を開いたら / に移る
// - ログインを使うビルドでは、ログインしていなければどの URL もログイン（/login?from=開こうとした URL）に移る。
//   ログインしたら開こうとした URL へ（なければ公開ページ /。上のバーからマイページの操作ができる）。ログイン中に /login を開いたら / へ
//   （公開ページ /u/:slug は段階 5-3 で作り、ここでログインなしで開けるものとして外す）
import 'package:go_router/go_router.dart';

import '../auth/auth_gate.dart';
import '../constants/app_texts.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/my_page.dart';
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

  /// ログインのあとに移る先。[from]（開こうとした URL）がこのサイトの中の URL ならそこ、ほかは公開ページ（/）
  /// （ほかのサイトの URL（//example.com など）には移らない）
  static String afterLogin(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//') || from.startsWith(login)) return home;
    return from;
  }
}

/// ログインしているかによる振り分け。移らなくてよければ null
/// - ログインしていない：/login 以外は /login へ（開こうとした URL を from に。/ のときは付けない）
/// - ログインしている：/login はログインのあとに移る先へ
String? loginRedirect(Uri uri, {required bool loggedIn}) {
  final atLogin = uri.path == AppRoutes.login;
  if (!loggedIn) {
    if (atLogin) return null;
    final from = uri.toString();
    return from == AppRoutes.home ? AppRoutes.login : Uri(path: AppRoutes.login, queryParameters: {'from': from}).toString();
  }
  return atLogin ? AppRoutes.afterLogin(uri.queryParameters['from']) : null;
}

/// ログイン・マイページの URL を使うか（--dart-define=ENABLE_ACCOUNT=true のときだけ）
const bool accountRoutesEnabled = bool.fromEnvironment('ENABLE_ACCOUNT');

/// 画面の切り替え（アプリ全体で 1 つ。テストでは毎回作る）
/// [gate] があり、ログインを使うとき（[enableAccount]）は、ログインしていなければログインに移る（loginRedirect）
GoRouter createAppRouter({
  String initialLocation = AppRoutes.home,
  bool enableAccount = accountRoutesEnabled,
  AuthGate? gate,
}) =>
    GoRouter(
      initialLocation: initialLocation,
      refreshListenable: enableAccount ? gate : null,
      redirect: enableAccount && gate != null ? (context, state) => loginRedirect(state.uri, loggedIn: gate.loggedIn) : null,
      routes: [
        GoRoute(path: AppRoutes.home, builder: (context, state) => const HomePage()),
        if (enableAccount) ...[
          GoRoute(path: AppRoutes.login, builder: (context, state) => const LoginPage()),
          GoRoute(
            path: AppRoutes.myPage,
            builder: (context, state) => const MyPage(),
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
