// lib/auth/auth_api.dart
//
// 認証（services/auth-phoenix）の呼び出し。パスワードは Firebase Auth が持ち、ここには残さない
// 返ってくる ID トークンは、API（services/api-hono）の Authorization: Bearer に使う
import '../api/json_client.dart';

/// ログイン中のトークン
class AuthSession {
  const AuthSession({required this.uid, required this.idToken, required this.refreshToken, required this.expiresAt});

  factory AuthSession.fromJson(Object? json, DateTime now) {
    final map = json is Map ? json : const {};
    final expiresIn = map['expiresIn'];
    return AuthSession(
      uid: '${map['uid'] ?? ''}',
      idToken: '${map['idToken'] ?? ''}',
      refreshToken: '${map['refreshToken'] ?? ''}',
      expiresAt: now.add(Duration(seconds: expiresIn is int ? expiresIn : 3600)),
    );
  }

  final String uid;
  final String idToken;

  /// ID トークンを取り直すためのもの（このタブの sessionStorage に置く）
  final String refreshToken;
  final DateTime expiresAt;

  /// 期限の 1 分前を過ぎたら取り直す
  bool expiresSoon(DateTime now) => !now.isBefore(expiresAt.subtract(const Duration(minutes: 1)));
}

/// 自分の情報
class AuthUser {
  const AuthUser({required this.uid, required this.email, required this.emailVerified});

  final String uid;
  final String email;
  final bool emailVerified;
}

class AuthApi {
  AuthApi(this._client, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final JsonClient _client;
  final DateTime Function() _now;

  Future<AuthSession> _session(String path, Map<String, Object?> body, {String? token}) async =>
      AuthSession.fromJson(await _client.post(path, body: body, token: token), _now());

  Future<AuthSession> signUp(String email, String password) =>
      _session('/auth/signup', {'email': email, 'password': password});

  Future<AuthSession> logIn(String email, String password) =>
      _session('/auth/login', {'email': email, 'password': password});

  Future<AuthSession> refresh(String refreshToken) => _session('/auth/refresh', {'refreshToken': refreshToken});

  Future<AuthUser> me(String idToken) async {
    final json = await _client.get('/auth/me', token: idToken);
    final map = json is Map ? json : const {};
    return AuthUser(uid: '${map['uid'] ?? ''}', email: '${map['email'] ?? ''}', emailVerified: map['emailVerified'] == true);
  }

  /// すべての端末からログアウト
  Future<void> logOut(String idToken) => _client.post('/auth/logout', body: const {}, token: idToken);

  Future<void> requestPasswordReset(String email) => _client.post('/auth/password/reset', body: {'email': email});

  Future<AuthSession> changePassword(String idToken, String newPassword) =>
      _session('/auth/password/change', {'newPassword': newPassword}, token: idToken);

  Future<void> deleteAccount(String idToken) => _client.delete('/auth/account', token: idToken);
}
