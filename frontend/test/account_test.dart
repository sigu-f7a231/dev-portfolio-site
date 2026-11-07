// ログインの状態・ログイン画面・マイページのテスト
// 対象：lib/auth/auth_controller.dart、lib/pages/login_page.dart、lib/pages/my_page.dart、
//       lib/state/providers.dart（ログインで Repository が替わる）
// 認証・API は偽物（test/fake_backend.dart）
//
// 実行：flutter test test/account_test.dart（frontend/ で）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dev_portfolio/api/json_client.dart';
import 'package:dev_portfolio/auth/auth_controller.dart';
import 'package:dev_portfolio/auth/auth_gate.dart';
import 'package:dev_portfolio/constants/app_texts.dart';
import 'package:dev_portfolio/data/api_portfolio_repository.dart';
import 'package:dev_portfolio/data/local_portfolio_repository.dart';
import 'package:dev_portfolio/data/portfolio_repository.dart';
import 'package:dev_portfolio/pages/login_page.dart';
import 'package:dev_portfolio/pages/home_page.dart';
import 'package:dev_portfolio/pages/my_page.dart';
import 'package:dev_portfolio/router/app_router.dart';
import 'package:dev_portfolio/state/providers.dart';
import 'package:dev_portfolio/theme/app_theme.dart';
import 'package:dev_portfolio/utils/browser/browser_stub.dart' as stub;
import 'package:dev_portfolio/utils/profile_store.dart';
import 'package:dev_portfolio/widgets/account_bar.dart';

import 'fake_backend.dart';
import 'test_assets.dart';

/// 偽の認証・API を使う ProviderContainer。[now] で AuthApi の時計を決める（古くすると毎回トークンを取り直す）
ProviderContainer _container(FakeBackend backend, {DateTime Function()? now}) {
  final container = ProviderContainer(overrides: [
    authApiProvider.overrideWithValue(backend.authApi(now: now)),
    portfolioApiProvider.overrideWith(
      (ref) => backend.portfolioApi(() => ref.read(authControllerProvider.notifier).idToken()),
    ),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<void> _settle(WidgetTester tester, [int frames = 15]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// [gate] を渡すと、main.dart と同じく、ログインしていなければログインに移る
Future<GoRouter> _pumpApp(WidgetTester tester, ProviderContainer container, String location, {bool gate = false}) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = createAppRouter(
    initialLocation: location,
    enableAccount: true,
    gate: gate ? container.read(authGateProvider) : null,
  );
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
  ));
  await _settle(tester);
  return router;
}

String _path(GoRouter router) => router.routerDelegate.currentConfiguration.uri.path;

int _count(FakeBackend backend, String call) => backend.calls.where((c) => c == call).length;

void main() {
  setUpAll(loadAppFont);

  setUp(() {
    useFileAssets();
    stub.SessionStore.clear();
    PortfolioRepository.reset();
  });
  tearDown(() {
    PortfolioRepository.reset();
    ProfileStore.instance.value = null;
  });

  group('AuthController', () {
    test('ログインすると、トークンを持ち、Repository が API に替わり、表示を読み直す（プロフィールも API から）', () async {
      final backend = FakeBackend();
      final container = _container(backend);
      expect(container.read(authControllerProvider), isNull);
      expect(container.read(portfolioRepositoryProvider), isA<LocalPortfolioRepository>());

      await container.read(authControllerProvider.notifier).logIn('  ${FakeBackend.email} ', FakeBackend.password);
      final session = container.read(authControllerProvider);
      expect(session?.idToken, 'id1');
      expect(stub.SessionStore.read(AuthController.storageKey), 'refresh1');
      expect(PortfolioRepository.instance, isA<ApiPortfolioRepository>());
      expect(container.read(portfolioRepositoryProvider), isA<ApiPortfolioRepository>());
      expect(container.read(dataRevisionProvider), 1);
      await pumpEventQueue();
      expect(backend.calls, contains('GET /api/me/draft'));
      expect(backend.lastToken, 'Bearer id1', reason: '読み直しはログインのトークンで');

      // もう一度ログインしても、Repository は替えない
      await container.read(authControllerProvider.notifier).logIn(FakeBackend.email, FakeBackend.password);
      expect(container.read(authControllerProvider)?.idToken, 'id2');
      expect(container.read(dataRevisionProvider), 1);
    });

    test('登録してもログインする', () async {
      final backend = FakeBackend()..signedUp = false;
      final container = _container(backend);
      await container.read(authControllerProvider.notifier).signUp('new@example.com', FakeBackend.password);
      expect(container.read(authControllerProvider), isNotNull);
      expect(backend.calls.first, 'POST /auth/signup');
    });

    test('ID トークン：期限が遠ければそのまま、近ければ取り直して覚え直す', () async {
      final backend = FakeBackend();
      final fresh = _container(backend);
      await fresh.read(authControllerProvider.notifier).logIn(FakeBackend.email, FakeBackend.password);
      expect(await fresh.read(authControllerProvider.notifier).idToken(), 'id1');

      final old = _container(backend, now: () => DateTime(2000));
      await old.read(authControllerProvider.notifier).logIn(FakeBackend.email, FakeBackend.password);
      // ログインした直後の読み直し（プロフィール）でも取り直すので、番号は決めない
      final token = await old.read(authControllerProvider.notifier).idToken();
      expect(token, isNot('id2'));
      expect(old.read(authControllerProvider)?.idToken, token);
      expect(stub.SessionStore.read(AuthController.storageKey), old.read(authControllerProvider)?.refreshToken);
      expect(backend.calls, contains('POST /auth/refresh'));
    });

    test('異常系：ログインしていなければ、ID トークンは 401', () async {
      final container = _container(FakeBackend());
      await expectLater(
        container.read(authControllerProvider.notifier).idToken(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
      );
    });

    test('restore：前にログインしていたら続ける。なければ・取り直せなければしない', () async {
      final backend = FakeBackend();
      expect(await _container(backend).read(authControllerProvider.notifier).restore(), isFalse);
      expect(backend.calls, isEmpty);

      stub.SessionStore.write(AuthController.storageKey, 'saved');
      final container = _container(backend);
      expect(await container.read(authControllerProvider.notifier).restore(), isTrue);
      expect(container.read(authControllerProvider), isNotNull);

      backend.failures['POST /auth/refresh'] = 401;
      final failed = _container(backend);
      expect(await failed.read(authControllerProvider.notifier).restore(), isFalse);
      expect(failed.read(authControllerProvider), isNull);
      expect(stub.SessionStore.read(AuthController.storageKey), isNull);
    });

    test('ログアウト：サーバーに知らせ、Local に戻す。サーバーが失敗してもログアウトする', () async {
      final backend = FakeBackend();
      final container = _container(backend);
      final auth = container.read(authControllerProvider.notifier);
      await auth.logOut(); // ログインしていなければ何もしない
      expect(backend.calls, isEmpty);

      await auth.logIn(FakeBackend.email, FakeBackend.password);
      await auth.logOut();
      expect(_count(backend, 'POST /auth/logout'), 1);
      expect(container.read(authControllerProvider), isNull);
      expect(PortfolioRepository.instance, isA<LocalPortfolioRepository>());
      expect(stub.SessionStore.read(AuthController.storageKey), isNull);
      expect(container.read(dataRevisionProvider), 2);

      await auth.logIn(FakeBackend.email, FakeBackend.password);
      backend.failures['POST /auth/logout'] = 401;
      await auth.logOut();
      expect(container.read(authControllerProvider), isNull);
    });

    test('退会：データを消してからアカウントを消し、ログアウトする', () async {
      final backend = FakeBackend();
      final container = _container(backend);
      final auth = container.read(authControllerProvider.notifier);
      await auth.logIn(FakeBackend.email, FakeBackend.password);
      await auth.deleteAccount();
      final deleteData = backend.calls.indexOf('DELETE /api/me');
      expect(deleteData, greaterThan(0));
      expect(backend.calls.indexOf('DELETE /auth/account'), greaterThan(deleteData));
      expect(container.read(authControllerProvider), isNull);
    });

    test('既定の Provider は、同じオリジンにつなぐ', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(authApiProvider), isNotNull);
      expect(container.read(portfolioApiProvider), isNotNull);
    });
  });

  group('ログインしていなければログインに移る（loginRedirect・AuthGate）', () {
    test('loginRedirect：ログインしていなければ /login へ（開こうとした URL を from に）', () {
      String? go(String location, {bool loggedIn = false}) => loginRedirect(Uri.parse(location), loggedIn: loggedIn);
      expect(go('/'), AppRoutes.login);
      expect(go('/me'), '/login?from=%2Fme');
      expect(go('/me/edit?tab=1'), '/login?from=%2Fme%2Fedit%3Ftab%3D1');
      expect(go('/login'), isNull);
      expect(go('/login?from=%2Fme'), isNull);
      // ログインしている
      expect(go('/', loggedIn: true), isNull);
      expect(go('/me', loggedIn: true), isNull);
      expect(go('/login', loggedIn: true), AppRoutes.home);
      expect(go('/login?from=%2Fme%2Fedit', loggedIn: true), AppRoutes.edit);
    });

    test('afterLogin：このサイトの中の URL だけ。ほかは公開ページ（/）', () {
      expect(AppRoutes.afterLogin(null), AppRoutes.home);
      expect(AppRoutes.afterLogin('/me/edit'), AppRoutes.edit);
      expect(AppRoutes.afterLogin('/'), AppRoutes.home);
      for (final bad in ['', 'me', 'https://example.com', '//example.com', '/login', '/login?from=%2F']) {
        expect(AppRoutes.afterLogin(bad), AppRoutes.home, reason: bad);
      }
    });

    test('AuthGate：ログインの状態に合わせて変わり、変わったときだけ知らせる', () async {
      final backend = FakeBackend();
      final container = _container(backend);
      final gate = container.read(authGateProvider);
      var notified = 0;
      gate.addListener(() => notified++);
      expect(gate.loggedIn, isFalse);
      await container.read(authControllerProvider.notifier).logIn(FakeBackend.email, FakeBackend.password);
      expect(gate.loggedIn, isTrue);
      await container.read(authControllerProvider.notifier).logIn(FakeBackend.email, FakeBackend.password);
      expect(notified, 1, reason: 'ログインしたままなら知らせない');
      await container.read(authControllerProvider.notifier).logOut();
      expect(gate.loggedIn, isFalse);
      expect(notified, 2);
      gate.loggedIn = false;
      expect(notified, 2);
    });

    testWidgets('ログインしていなければ / を開いてもログイン画面', (tester) async {
      final router = await _pumpApp(tester, _container(FakeBackend(withProfile: true)), AppRoutes.home, gate: true);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(_path(router), AppRoutes.login);
    });

    testWidgets('/me/edit を開く → ログイン → 開こうとした /me/edit に移る', (tester) async {
      final router = await _pumpApp(tester, _container(FakeBackend(withProfile: true)), AppRoutes.edit, gate: true);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.uri.queryParameters['from'], AppRoutes.edit);

      await tester.enterText(find.byKey(const Key('login-email')), FakeBackend.email);
      await tester.enterText(find.byKey(const Key('login-password')), FakeBackend.password);
      await tester.tap(find.byKey(const Key('login-submit')));
      await _settle(tester);
      expect(_path(router), AppRoutes.edit);
      expect(find.text(RouteTexts.edit), findsOneWidget);
    });

    testWidgets('ログイン中に /login を開くと公開ページ（上にバー）。バーでログアウトするとログイン画面', (tester) async {
      final container = _container(FakeBackend(withProfile: true));
      await tester.runAsync(() => container.read(authControllerProvider.notifier).logIn(FakeBackend.email, FakeBackend.password));
      final router = await _pumpApp(tester, container, AppRoutes.login, gate: true);
      expect(_path(router), AppRoutes.home);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(AccountBar), findsOneWidget);

      await tester.tap(find.byKey(const Key('bar-logout')));
      await _settle(tester);
      expect(_path(router), AppRoutes.login);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });

  group('ログイン画面', () {
    testWidgets('ログインすると公開ページに移り、上のバーにメールアドレスと公開の状態を出す', (tester) async {
      final backend = FakeBackend(withProfile: true);
      final router = await _pumpApp(tester, _container(backend), AppRoutes.login);
      expect(find.byType(LoginPage), findsOneWidget);

      await tester.enterText(find.byKey(const Key('login-email')), FakeBackend.email);
      await tester.enterText(find.byKey(const Key('login-password')), FakeBackend.password);
      await tester.tap(find.byKey(const Key('login-submit')));
      await _settle(tester);

      expect(_path(router), AppRoutes.home);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(AccountBar), findsOneWidget);
      expect(find.text(FakeBackend.email), findsOneWidget);
      expect(find.text(AccountTexts.notPublished), findsOneWidget);
      expect(find.text('偽物 太郎'), findsWidgets, reason: '公開ページは API のデータ');
      expect(tester.takeException(), isNull);
    });

    testWidgets('入力の確認：メールアドレスがない・パスワードが短い', (tester) async {
      final backend = FakeBackend();
      await _pumpApp(tester, _container(backend), AppRoutes.login);
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();
      expect(find.text(AccountTexts.emailRequired), findsOneWidget);

      await tester.enterText(find.byKey(const Key('login-email')), FakeBackend.email);
      await tester.enterText(find.byKey(const Key('login-password')), 'short');
      await tester.testTextInput.receiveAction(TextInputAction.done); // Enter でも送る
      await tester.pump();
      expect(find.text(AccountTexts.passwordTooShort), findsOneWidget);
      expect(backend.calls, isEmpty);
    });

    testWidgets('異常系：パスワードが違えば、サーバーの言葉を出す', (tester) async {
      final backend = FakeBackend();
      final router = await _pumpApp(tester, _container(backend), AppRoutes.login);
      await tester.enterText(find.byKey(const Key('login-email')), FakeBackend.email);
      await tester.enterText(find.byKey(const Key('login-password')), 'wrong-password');
      await tester.tap(find.byKey(const Key('login-submit')));
      await _settle(tester);
      expect(find.text('メールアドレスかパスワードが違います'), findsOneWidget);
      expect(_path(router), AppRoutes.login);
    });

    testWidgets('登録に切り替える：パスワードの案内。もう登録済みならエラー、新しければ登録して公開ページへ', (tester) async {
      final backend = FakeBackend(withProfile: true);
      final router = await _pumpApp(tester, _container(backend), AppRoutes.login);
      await tester.tap(find.text(AccountTexts.toSignUp));
      await tester.pump();
      expect(find.text(AccountTexts.passwordHint), findsOneWidget);
      expect(find.text(AccountTexts.forgotPassword), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility)); // パスワードを見せる
      await tester.pump();
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.enterText(find.byKey(const Key('login-email')), FakeBackend.email);
      await tester.enterText(find.byKey(const Key('login-password')), FakeBackend.password);
      await tester.tap(find.byKey(const Key('login-submit')));
      await _settle(tester);
      expect(find.text('このメールアドレスはもう登録されています'), findsOneWidget);

      backend.signedUp = false;
      await tester.tap(find.byKey(const Key('login-submit')));
      await _settle(tester);
      expect(_path(router), AppRoutes.home);
      expect(find.text(AccountTexts.signedUp), findsOneWidget);

    });

    testWidgets('登録からログインに戻す', (tester) async {
      await _pumpApp(tester, _container(FakeBackend()), AppRoutes.login);
      await tester.tap(find.text(AccountTexts.toSignUp));
      await tester.pump();
      await tester.tap(find.text(AccountTexts.toLogIn));
      await tester.pump();
      expect(find.text(AccountTexts.forgotPassword), findsOneWidget);
    });

    testWidgets('パスワードを忘れたら：メールアドレスがなければ案内、あれば再設定のメールを送る', (tester) async {
      final backend = FakeBackend();
      await _pumpApp(tester, _container(backend), AppRoutes.login);
      await tester.tap(find.text(AccountTexts.forgotPassword));
      await tester.pump();
      expect(find.text(AccountTexts.emailRequired), findsOneWidget);

      await tester.enterText(find.byKey(const Key('login-email')), ' ${FakeBackend.email} ');
      await tester.tap(find.text(AccountTexts.forgotPassword));
      await _settle(tester);
      expect(find.text(AccountTexts.resetSent), findsOneWidget);
      expect(backend.calls, ['POST /auth/password/reset']);
    });
  });

  group('公開ページの上のバー（AccountBar）', () {
    Future<(FakeBackend, ProviderContainer, GoRouter)> openHome(WidgetTester tester, {FakeBackend? backend}) async {
      final b = backend ?? FakeBackend(withProfile: true);
      final container = _container(b);
      await tester.runAsync(() => container.read(authControllerProvider.notifier).logIn(FakeBackend.email, FakeBackend.password));
      await tester.runAsync(() => ProfileStore.instance.loading);
      final router = await _pumpApp(tester, container, AppRoutes.home, gate: true);
      return (b, container, router);
    }

    testWidgets('ログインしていなければ出さない', (tester) async {
      ProfileStore.instance.value = null;
      await _pumpApp(tester, _container(FakeBackend()), AppRoutes.home);
      expect(find.byType(AccountBar), findsNothing);
    });

    testWidgets('公開する・公開を止める（バーの表示が切り替わる）', (tester) async {
      final backend = FakeBackend(withProfile: true)..slug = 'sample';
      await openHome(tester, backend: backend);
      expect(find.text(AccountTexts.notPublished), findsOneWidget);

      await tester.tap(find.byKey(const Key('bar-publish')));
      await _settle(tester);
      expect(find.text(AccountTexts.published(1)), findsOneWidget);
      expect(find.text(AccountTexts.publishedDone), findsOneWidget);

      await tester.tap(find.byKey(const Key('bar-unpublish')));
      await _settle(tester);
      expect(backend.publishedVersion, isNull);
      expect(find.byKey(const Key('bar-publish')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('異常系：公開できなければ理由を出す（名前がまだない）', (tester) async {
      await openHome(tester);
      await tester.tap(find.byKey(const Key('bar-publish')));
      await _settle(tester);
      expect(find.text('公開する前に名前を決めてください'), findsOneWidget);
      expect(find.text(AccountTexts.notPublished), findsOneWidget);
    });

    testWidgets('［マイページ］はダイアログ：名前を決めて閉じると、バーも読み直す（公開ページで編集するは出さない）', (tester) async {
      final (backend, _, router) = await openHome(tester);
      await tester.tap(find.byKey(const Key('bar-mypage')));
      await _settle(tester);
      expect(find.byType(MyPagePanel), findsOneWidget);
      expect(find.text(AccountTexts.openEditor), findsNothing);

      await tester.enterText(find.byKey(const Key('my-slug')), 'sample');
      await tester.tap(find.byKey(const Key('my-slug-save')));
      await _settle(tester);
      expect(backend.slug, 'sample');
      await tester.tap(find.byKey(const Key('my-publish')));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('bar-mypage-close')));
      await _settle(tester);
      expect(find.byType(MyPagePanel), findsNothing);
      expect(find.text(AccountTexts.published(1)), findsOneWidget, reason: '閉じたらバーを読み直す');
      expect(_path(router), AppRoutes.home);
    });

    testWidgets('ダイアログでログアウトすると、ダイアログを閉じてログイン画面', (tester) async {
      final (_, container, router) = await openHome(tester);
      await tester.tap(find.byKey(const Key('bar-mypage')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('my-logout')));
      await _settle(tester);
      expect(container.read(authControllerProvider), isNull);
      expect(find.byType(MyPagePanel), findsNothing);
      expect(_path(router), AppRoutes.login);
    });

    testWidgets('ダイアログで退会すると、ダイアログを閉じてログイン画面', (tester) async {
      final (backend, container, router) = await openHome(tester);
      await tester.tap(find.byKey(const Key('bar-mypage')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('my-delete')));
      await _settle(tester, 5);
      await tester.tap(find.byKey(const Key('delete-confirm')));
      await _settle(tester);
      expect(_count(backend, 'DELETE /auth/account'), 1);
      expect(container.read(authControllerProvider), isNull);
      expect(find.byType(MyPagePanel), findsNothing);
      expect(_path(router), AppRoutes.login);
    });

    testWidgets('異常系：読めなければ、バーはメールアドレスの代わりに「ログイン中」', (tester) async {
      final backend = FakeBackend(withProfile: true)..failures['GET /api/me'] = 500;
      await openHome(tester, backend: backend);
      expect(find.text(AccountTexts.loggedIn), findsOneWidget);
      expect(find.text('失敗 500'), findsOneWidget);
    });
  });

  group('マイページ', () {
    /// ログインしてからマイページを開く
    Future<(FakeBackend, ProviderContainer, GoRouter)> openLoggedIn(WidgetTester tester, {FakeBackend? backend}) async {
      final b = backend ?? FakeBackend();
      final container = _container(b);
      await tester.runAsync(() => container.read(authControllerProvider.notifier).logIn(FakeBackend.email, FakeBackend.password));
      final router = await _pumpApp(tester, container, AppRoutes.myPage);
      return (b, container, router);
    }

    testWidgets('ログインしていなければ案内し、ログインに移れる', (tester) async {
      final router = await _pumpApp(tester, _container(FakeBackend()), AppRoutes.myPage);
      expect(find.text(AccountTexts.needLogIn), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, AccountTexts.logIn));
      await _settle(tester);
      expect(_path(router), AppRoutes.login);
    });

    testWidgets('公開ページの名前を決める（誤りは理由を出す）・公開する・公開を止める', (tester) async {
      final (backend, _, _) = await openLoggedIn(tester);
      expect(find.text(FakeBackend.email), findsOneWidget);

      // 名前を決める前に公開しようとすると、サーバーの言葉を出す
      await tester.tap(find.byKey(const Key('my-publish')));
      await _settle(tester);
      expect(find.text('公開する前に名前を決めてください'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('my-slug')), 'ab');
      await tester.tap(find.byKey(const Key('my-slug-save')));
      await _settle(tester);
      expect(find.byKey(const Key('my-error')), findsOneWidget);
      expect(find.textContaining('3 文字以上'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('my-slug')), ' sample ');
      await tester.tap(find.byKey(const Key('my-slug-save')));
      await _settle(tester);
      expect(backend.slug, 'sample');
      expect(find.text(AccountTexts.slugSaved), findsOneWidget);
      expect(find.byKey(const Key('my-error')), findsNothing);

      await tester.tap(find.byKey(const Key('my-publish')));
      await _settle(tester);
      expect(find.text(AccountTexts.published(1)), findsOneWidget);
      expect(find.text(AccountTexts.latest(1)), findsOneWidget);
      expect(find.byKey(const Key('my-unpublish')), findsOneWidget);

      await tester.tap(find.byKey(const Key('my-unpublish')));
      await _settle(tester);
      expect(find.text(AccountTexts.notPublished), findsOneWidget);
      expect(find.byKey(const Key('my-unpublish')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('前に決めた名前を入れて出す', (tester) async {
      final backend = FakeBackend()
        ..slug = 'sample'
        ..latestVersion = 2
        ..publishedVersion = 1;
      await openLoggedIn(tester, backend: backend);
      expect(find.widgetWithText(TextField, 'sample'), findsOneWidget);
      expect(find.text(AccountTexts.published(1)), findsOneWidget);
      expect(find.text(AccountTexts.latest(2)), findsOneWidget);
    });

    testWidgets('異常系：読めなければエラーを出す', (tester) async {
      final backend = FakeBackend()..failures['GET /api/me'] = 500;
      await openLoggedIn(tester, backend: backend);
      expect(find.text('失敗 500'), findsOneWidget);
    });

    testWidgets('［編集する］で / に移る', (tester) async {
      final (_, _, router) = await openLoggedIn(tester);
      await tester.tap(find.text(AccountTexts.openEditor));
      await _settle(tester);
      expect(_path(router), AppRoutes.home);
    });

    testWidgets('ログアウトするとログイン画面へ', (tester) async {
      final (backend, container, router) = await openLoggedIn(tester);
      await tester.tap(find.byKey(const Key('my-logout')));
      await _settle(tester);
      expect(_path(router), AppRoutes.login);
      expect(container.read(authControllerProvider), isNull);
      expect(_count(backend, 'POST /auth/logout'), 1);
    });

    testWidgets('退会：確かめてから。やめれば何もしない。進めばデータとアカウントを消し、/ へ', (tester) async {
      final (backend, container, router) = await openLoggedIn(tester);
      await tester.tap(find.byKey(const Key('my-delete')));
      await _settle(tester, 5);
      expect(find.text(AccountTexts.deleteConfirmTitle), findsOneWidget);
      await tester.tap(find.text(AppTexts.cancel));
      await _settle(tester, 5);
      expect(_count(backend, 'DELETE /auth/account'), 0);
      expect(container.read(authControllerProvider), isNotNull);

      await tester.tap(find.byKey(const Key('my-delete')));
      await _settle(tester, 5);
      await tester.tap(find.byKey(const Key('delete-confirm')));
      await _settle(tester);
      expect(_count(backend, 'DELETE /api/me'), 1);
      expect(_count(backend, 'DELETE /auth/account'), 1);
      expect(container.read(authControllerProvider), isNull);
      expect(_path(router), AppRoutes.home);
    });
  });
}
