// lib/api/json_client.dart
//
// API（services/api-hono）・認証（services/auth-phoenix）に JSON を送って受け取る
// - つなぎ先：--dart-define=API_BASE / AUTH_BASE（既定は空＝同じオリジン。nginx が /api/・/auth/ を転送する）
//   flutter run で直接つなぐときは API_BASE=http://localhost:8787、AUTH_BASE=http://localhost:4100（各サービスに ALLOWED_ORIGIN が要る）
// - 失敗は ApiException（{"error": {"code", "message", "details"}} の中身）。つながらないときは status 0
// - テストでは http の MockClient を渡す
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/app_texts.dart';

/// API・認証のエラー
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message, [this.details = const []]);

  /// HTTP の状態（つながらないときは 0）
  final int status;
  final String code;
  final String message;

  /// 入力の誤りの一覧（あれば）
  final List<String> details;

  @override
  String toString() => details.isEmpty ? message : '$message\n${details.map((d) => '・$d').join('\n')}';
}

/// つなぎ先（ビルドの設定）
class ApiEndpoints {
  ApiEndpoints._(); // インスタンスを作らせないための private コンストラクタ（呼ばれない） // coverage:ignore-line

  static const String apiBase = String.fromEnvironment('API_BASE');
  static const String authBase = String.fromEnvironment('AUTH_BASE');
}

class JsonClient {
  JsonClient({required this.baseUrl, http.Client? client}) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  /// [method] で [path] に送る。[body] があれば JSON で、[token] があれば Authorization: Bearer で
  Future<Object?> send(String method, String path, {Object? body, String? token}) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final http.Response response;
    try {
      response = await http.Response.fromStream(await _client.send(request));
    } catch (_) {
      throw ApiException(0, 'network', AccountTexts.network);
    }

    final text = utf8.decode(response.bodyBytes);
    Object? json;
    try {
      json = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      json = null;
    }
    if (response.statusCode >= 200 && response.statusCode < 300) return json;

    final error = json is Map && json['error'] is Map ? json['error'] as Map : const {};
    final details = error['details'];
    throw ApiException(
      response.statusCode,
      '${error['code'] ?? 'http_${response.statusCode}'}',
      '${error['message'] ?? AccountTexts.unknownError}',
      [if (details is List) for (final d in details) '$d'],
    );
  }

  Future<Object?> get(String path, {String? token}) => send('GET', path, token: token);
  Future<Object?> post(String path, {Object? body, String? token}) => send('POST', path, body: body, token: token);
  Future<Object?> put(String path, {Object? body, String? token}) => send('PUT', path, body: body, token: token);
  Future<Object?> delete(String path, {String? token}) => send('DELETE', path, token: token);
}
