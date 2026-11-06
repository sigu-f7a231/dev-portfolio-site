// lib/src/app.dart
//
// ルーティングとミドルウェア。
//   GET /healthz                  … 動作確認（アップタイムチェック・コンテナのヘルスチェック用）
//   GET /api/profile              … プロフィール（Home / About）
//   GET /api/projects/<type>      … type は work か private
// 応答はすべて JSON。エラーは {"error": {"code": ..., "message": ...}}。
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'data_store.dart';
import 'logging.dart';

/// [allowedOrigin] を渡すと、その Origin からのブラウザのアクセスを許す（flutter run で別ポートから呼ぶとき用）。
/// [log] はログ 1 行（JSON）の出力先。省略すると標準出力。
Handler buildHandler(
  DataStore store, {
  String? allowedOrigin,
  void Function(String line)? log,
}) {
  final router = Router(notFoundHandler: (_) => _error(404, 'not_found', 'ページがありません'))
    ..get('/healthz', (Request _) => _json({'status': 'ok'}, cache: 'no-store'))
    ..get('/api/profile', (Request _) => _respond(store.profile))
    ..get('/api/projects/<type>', (Request _, String type) {
      final t = ProjectType.values.asNameMap()[type];
      if (t == null) {
        return _error(404, 'unknown_type', 'type は work か private です');
      }
      return _respond(() => store.projects(t));
    });

  return const Pipeline()
      .addMiddleware(structuredLogger(log ?? stdout.writeln))
      .addMiddleware(_cors(allowedOrigin))
      .addHandler(router.call);
}

Future<Response> _respond(Future<Map<String, Object?>> Function() load) async {
  try {
    return _json(await load());
  } on DataNotFound catch (e) {
    return _error(404, 'data_not_found', '${e.name}.yaml がありません');
  } on InvalidData catch (e) {
    // データの置き方の誤り。ログで気づけるよう 500 にする
    return _error(500, 'invalid_data', '${e.name}.yaml: ${e.message}');
  }
}

Response _json(Object body, {int status = 200, String? cache}) => Response(
      status,
      body: jsonEncode(body),
      headers: {
        'content-type': 'application/json; charset=utf-8',
        // データはほとんど変わらないので、CDN（Cloudflare）で短くキャッシュさせる
        'cache-control': cache ?? 'public, max-age=60',
      },
    );

Response _error(int status, String code, String message) => _json(
      {
        'error': {'code': code, 'message': message},
      },
      status: status,
      cache: 'no-store',
    );

Middleware _cors(String? origin) => (inner) => (request) async {
      if (origin == null || origin.isEmpty) return inner(request);
      const allow = {'access-control-allow-methods': 'GET, OPTIONS'};
      if (request.method == 'OPTIONS') {
        return Response(204,
            headers: {'access-control-allow-origin': origin, ...allow});
      }
      final response = await inner(request);
      return response.change(headers: {
        'access-control-allow-origin': origin,
        'vary': 'Origin',
        ...allow,
      });
    };
