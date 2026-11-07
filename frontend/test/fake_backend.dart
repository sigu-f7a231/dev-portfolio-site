// test/fake_backend.dart
//
// テスト用の偽の認証（services/auth-phoenix）と API（services/api-hono）。http の MockClient で答える
// - 利用者は 1 人（test@example.com / password123）。トークンは呼ぶたびに番号が増える
// - 編集中のデータ（/api/me/draft）は、updatedAt が違えば 409（ほかの場所で先に変わった）
// - [failures] に「メソッド パス」→ 状態 を入れると、その呼び出しを 1 回だけ失敗させる
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dev_portfolio/api/json_client.dart';
import 'package:dev_portfolio/api/portfolio_api.dart';
import 'package:dev_portfolio/auth/auth_api.dart';

class FakeBackend {
  static const String email = 'test@example.com';
  static const String password = 'password123';
  static const String base = 'http://fake';

  final List<String> calls = [];
  final Map<String, int> failures = {};

  /// 保存のときに 409 を返す回数
  int conflicts = 0;

  int _tokens = 0;
  bool signedUp = true;
  String? slug;
  int latestVersion = 0;
  int? publishedVersion;
  Map<String, dynamic> data = {};
  String? updatedAt;
  int _saves = 0;

  /// 最後に受け取った Authorization
  String? lastToken;

  late final MockClient client = MockClient(_handle);
  late final JsonClient jsonClient = JsonClient(baseUrl: base, client: client);

  AuthApi authApi({DateTime Function()? now}) => AuthApi(jsonClient, now: now);
  PortfolioApi portfolioApi([Future<String> Function()? token]) => PortfolioApi(jsonClient, token ?? () async => 'token');

  Map<String, Object?> _session() {
    _tokens++;
    return {'uid': 'u1', 'idToken': 'id$_tokens', 'refreshToken': 'refresh$_tokens', 'expiresIn': 3600};
  }

  Map<String, Object?> _me() => {'slug': slug, 'latestVersion': latestVersion, 'publishedVersion': publishedVersion};

  http.Response _json(int status, Object? body) =>
      http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json'});

  http.Response _error(int status, String code, String message, [List<String> details = const []]) =>
      _json(status, {'error': {'code': code, 'message': message, if (details.isNotEmpty) 'details': details}});

  Future<http.Response> _handle(http.Request request) async {
    final key = '${request.method} ${request.url.path}';
    calls.add(key);
    lastToken = request.headers['Authorization'];
    final failure = failures.remove(key);
    if (failure != null) return _error(failure, 'fake_$failure', '失敗 $failure');
    final body = request.body.isEmpty ? const {} : jsonDecode(request.body) as Map;

    switch (key) {
      case 'POST /auth/signup':
        if (signedUp) return _error(409, 'email_exists', 'このメールアドレスはもう登録されています');
        signedUp = true;
        return _json(201, _session());
      case 'POST /auth/login':
        if (body['email'] != email || body['password'] != password) {
          return _error(401, 'invalid_credentials', 'メールアドレスかパスワードが違います');
        }
        return _json(200, _session());
      case 'POST /auth/refresh':
      case 'POST /auth/password/change':
        return _json(200, _session());
      case 'GET /auth/me':
        return _json(200, {'uid': 'u1', 'email': email, 'emailVerified': false});
      case 'POST /auth/logout':
      case 'POST /auth/password/reset':
        return _json(200, {'ok': true});
      case 'DELETE /auth/account':
        return http.Response('', 204);
      case 'GET /api/me':
        return _json(200, _me());
      case 'DELETE /api/me':
        data = {};
        updatedAt = null;
        return http.Response('', 204);
      case 'PUT /api/me/slug':
        final value = '${body['slug']}';
        if (value.length < 3) return _error(400, 'invalid_slug', '公開ページの名前が正しくありません', ['3 文字以上']);
        slug = value;
        return _json(200, _me());
      case 'POST /api/me/publish':
        if (slug == null) return _error(400, 'missing', '公開する前に名前を決めてください');
        latestVersion++;
        publishedVersion = latestVersion;
        return _json(200, _me());
      case 'DELETE /api/me/publish':
        publishedVersion = null;
        return _json(200, _me());
      case 'GET /api/me/draft':
        return _json(200, {'data': data, 'updatedAt': updatedAt});
      case 'PUT /api/me/draft':
        if (conflicts > 0) {
          conflicts--;
          updatedAt = 'other-${_saves++}';
          return _error(409, 'conflict', 'ほかの場所で先に変わりました');
        }
        if (body['updatedAt'] != updatedAt) return _error(409, 'conflict', 'ほかの場所で先に変わりました');
        data = Map<String, dynamic>.from(body['data'] as Map);
        updatedAt = 'saved-${_saves++}';
        return _json(200, {'data': data, 'updatedAt': updatedAt});
    }
    return _error(404, 'not_found', 'ありません');
  }
}
