// API・認証の呼び出しのテスト
// 対象：lib/api/json_client.dart、lib/api/portfolio_api.dart、lib/auth/auth_api.dart
//
// 実行：flutter test test/api_client_test.dart（frontend/ で）
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:dev_portfolio/api/json_client.dart';
import 'package:dev_portfolio/api/portfolio_api.dart';
import 'package:dev_portfolio/auth/auth_api.dart';
import 'package:dev_portfolio/constants/app_texts.dart';

import 'fake_backend.dart';

JsonClient _client(Future<http.Response> Function(http.Request) handler) =>
    JsonClient(baseUrl: 'http://x', client: MockClient(handler));

void main() {
  group('JsonClient', () {
    test('JSON を送り、トークンを付け、JSON を返す', () async {
      late http.Request seen;
      final client = _client((r) async {
        seen = r;
        return http.Response.bytes(utf8.encode('{"ok":"はい"}'), 200);
      });
      expect(await client.post('/a', body: {'x': 1}, token: 't'), {'ok': 'はい'});
      expect(seen.url.toString(), 'http://x/a');
      expect(seen.headers['Authorization'], 'Bearer t');
      expect(seen.headers['Content-Type'], startsWith('application/json'));
      expect(jsonDecode(seen.body), {'x': 1});

      expect(await client.get('/b'), {'ok': 'はい'});
      expect(seen.headers.containsKey('Authorization'), isFalse);
      expect(seen.body, isEmpty);
      await client.put('/c', body: const {});
      expect(seen.method, 'PUT');
      await client.delete('/d');
      expect(seen.method, 'DELETE');
    });

    test('中身がない・JSON でない成功は null', () async {
      expect(await _client((_) async => http.Response('', 204)).delete('/a'), isNull);
      expect(await _client((_) async => http.Response('<html>', 200)).get('/a'), isNull);
    });

    test('異常系：エラーの JSON は ApiException（code・message・details）', () async {
      final client = _client((_) async => http.Response.bytes(
            utf8.encode('{"error":{"code":"invalid","message":"正しくありません","details":["名前","期間"]}}'),
            400,
          ));
      final error = await client.get('/a').then<ApiException?>((_) => null, onError: (Object e) => e as ApiException);
      expect(error!.status, 400);
      expect(error.code, 'invalid');
      expect(error.details, ['名前', '期間']);
      expect(error.toString(), '正しくありません\n・名前\n・期間');
    });

    test('異常系：エラーの形でなければ http_状態 と決まった言葉', () async {
      final client = _client((_) async => http.Response('oops', 502));
      await expectLater(
        client.get('/a'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'http_502')
            .having((e) => e.toString(), 'message', AccountTexts.unknownError)),
      );
    });

    test('異常系：つながらなければ status 0', () async {
      final client = _client((_) async => throw http.ClientException('down'));
      await expectLater(
        client.get('/a'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 0).having((e) => e.message, 'message', AccountTexts.network)),
      );
    });

    test('つなぎ先の既定は同じオリジン（空）', () {
      expect(ApiEndpoints.apiBase, isEmpty);
      expect(ApiEndpoints.authBase, isEmpty);
      expect(JsonClient(baseUrl: '').baseUrl, isEmpty); // 本物の http.Client を作れる
    });
  });

  group('AuthApi', () {
    late FakeBackend backend;
    late AuthApi api;
    final now = DateTime(2026, 1, 1, 12);
    setUp(() {
      backend = FakeBackend();
      api = backend.authApi(now: () => now);
    });

    test('ログイン・登録・取り直し：トークンと期限', () async {
      final session = await api.logIn(FakeBackend.email, FakeBackend.password);
      expect(session.uid, 'u1');
      expect(session.idToken, 'id1');
      expect(session.refreshToken, 'refresh1');
      expect(session.expiresAt, now.add(const Duration(hours: 1)));
      expect(session.expiresSoon(now), isFalse);
      expect(session.expiresSoon(now.add(const Duration(minutes: 59))), isTrue);

      backend.signedUp = false;
      expect((await api.signUp('new@example.com', FakeBackend.password)).idToken, 'id2');
      expect((await api.refresh('refresh2')).idToken, 'id3');
      expect((await api.changePassword('id3', 'newpassword')).idToken, 'id4');
      expect(backend.lastToken, 'Bearer id3');
    });

    test('自分の情報・ログアウト・再設定のメール・退会', () async {
      final user = await api.me('id1');
      expect(user.email, FakeBackend.email);
      expect(user.emailVerified, isFalse);
      expect(backend.lastToken, 'Bearer id1');
      await api.logOut('id1');
      await api.requestPasswordReset(FakeBackend.email);
      await api.deleteAccount('id1');
      expect(backend.calls, ['GET /auth/me', 'POST /auth/logout', 'POST /auth/password/reset', 'DELETE /auth/account']);
    });

    test('異常系：パスワードが違えば 401', () async {
      await expectLater(api.logIn(FakeBackend.email, 'wrong-password'), throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)));
    });

    test('形が違う答えでも落ちない（既定の値）', () {
      final session = AuthSession.fromJson('x', now);
      expect(session.uid, isEmpty);
      expect(session.expiresAt, now.add(const Duration(seconds: 3600)));
    });

    test('AuthApi の時計の既定は今', () async {
      final session = await FakeBackend().authApi().logIn(FakeBackend.email, FakeBackend.password);
      expect(session.expiresAt.isAfter(DateTime.now()), isTrue);
    });
  });

  group('PortfolioApi', () {
    late FakeBackend backend;
    late PortfolioApi api;
    setUp(() {
      backend = FakeBackend();
      api = backend.portfolioApi(() async => 'tok');
    });

    test('自分の情報・名前・公開・公開をやめる・すべて消す', () async {
      var me = await api.me();
      expect(me.slug, isNull);
      expect(me.latestVersion, 0);
      expect(me.publishedVersion, isNull);
      expect(backend.lastToken, 'Bearer tok');

      me = await api.setSlug('sample');
      expect(me.slug, 'sample');
      me = await api.publish();
      expect(me.publishedVersion, 1);
      expect(me.latestVersion, 1);
      me = await api.unpublish();
      expect(me.publishedVersion, isNull);
      await api.deleteAll();
      expect(backend.calls.last, 'DELETE /api/me');
    });

    test('編集中のデータを読み、書く', () async {
      var draft = await api.draft();
      expect(draft.updatedAt, isNull);
      expect(draft.data, isEmpty);
      draft = await api.saveDraft({'profile': {}}, null);
      expect(draft.updatedAt, 'saved-0');
      expect((await api.draft()).data, {'profile': {}});
    });

    test('形が違う答えでも落ちない', () {
      expect(MeInfo.fromJson(null).latestVersion, 0);
      expect(Draft.fromJson(null).updatedAt, isNull);
    });
  });
}
