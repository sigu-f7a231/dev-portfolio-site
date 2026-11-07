// lib/auth/auth_controller.dart
//
// ログインの状態（Riverpod）。ログインしている間は ID トークンを持ち、期限が近ければ取り直す
// - ログイン・登録したら、Repository を API（ApiPortfolioRepository）に切り替え、表示を読み直す
// - ログアウト・退会したら、Local（このタブの中だけ）に戻す
// - 更新用のトークンはこのタブの sessionStorage に置き、読み込み直しても続けてログインしていられる（restore）
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/json_client.dart';
import '../api/portfolio_api.dart';
import '../constants/app_texts.dart';
import '../data/api_portfolio_repository.dart';
import '../data/local_portfolio_repository.dart';
import '../data/portfolio_repository.dart';
import '../state/providers.dart';
import '../utils/browser/browser.dart';
import '../utils/profile_store.dart';
import 'auth_api.dart';

/// 認証（services/auth-phoenix）
final authApiProvider = Provider<AuthApi>((ref) => AuthApi(JsonClient(baseUrl: ApiEndpoints.authBase)));

/// API（services/api-hono）。トークンはログインの状態からもらう
final portfolioApiProvider = Provider<PortfolioApi>(
  (ref) => PortfolioApi(JsonClient(baseUrl: ApiEndpoints.apiBase), () => ref.read(authControllerProvider.notifier).idToken()),
);

/// ログイン中ならトークン、していなければ null
final authControllerProvider = NotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends Notifier<AuthSession?> {
  /// 更新用のトークンを置く sessionStorage のキー
  static const String storageKey = 'auth_refresh';

  @override
  AuthSession? build() => null;

  AuthApi get _api => ref.read(authApiProvider);

  Future<void> logIn(String email, String password) async => _begin(await _api.logIn(email.trim(), password));

  Future<void> signUp(String email, String password) async => _begin(await _api.signUp(email.trim(), password));

  /// このタブで前にログインしていたら、続けてログインする（できたら true）
  Future<bool> restore() async {
    final refreshToken = SessionStore.read(storageKey);
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      _begin(await _api.refresh(refreshToken));
      return true;
    } on ApiException {
      SessionStore.remove(storageKey);
      return false;
    }
  }

  /// 使える ID トークン（期限が近ければ取り直す）。ログインしていなければ 401 の ApiException
  Future<String> idToken() async {
    final session = state;
    if (session == null) throw ApiException(401, 'unauthorized', AccountTexts.needLogIn);
    if (!session.expiresSoon(DateTime.now())) return session.idToken;
    final renewed = await _api.refresh(session.refreshToken);
    state = renewed;
    SessionStore.write(storageKey, renewed.refreshToken);
    return renewed.idToken;
  }

  /// すべての端末からログアウト（サーバーに届かなくても、この画面ではログアウトする）
  Future<void> logOut() async {
    final session = state;
    if (session != null) {
      try {
        await _api.logOut(session.idToken);
      } on ApiException {
        // 期限切れなど。この画面のログインは消す
      }
    }
    _end();
  }

  /// 退会：先にデータを消し、それからアカウントを消す
  Future<void> deleteAccount() async {
    await ref.read(portfolioApiProvider).deleteAll();
    await _api.deleteAccount(await idToken());
    _end();
  }

  // state を先に変える（読み直しが API を呼ぶとき、もうトークンを使えるように）
  void _begin(AuthSession session) {
    final wasLoggedIn = state != null;
    SessionStore.write(storageKey, session.refreshToken);
    state = session;
    if (!wasLoggedIn) _switchRepository(ApiPortfolioRepository(ref.read(portfolioApiProvider)));
  }

  void _end() {
    final wasLoggedIn = state != null;
    SessionStore.remove(storageKey);
    state = null;
    if (wasLoggedIn) _switchRepository(LocalPortfolioRepository());
  }

  /// Repository を替え、プロフィールと Work / Private を読み直す
  void _switchRepository(PortfolioRepository repository) {
    PortfolioRepository.use(repository);
    ProfileStore.instance.value = null;
    unawaited(ProfileStore.instance.load().catchError((_) {}));
    ref.read(dataRevisionProvider.notifier).bump();
  }
}
