// lib/src/logging.dart
//
// 1 リクエスト 1 行の JSON ログ。Cloud Run では標準出力の JSON がそのまま
// Cloud Logging の構造化ログになり、severity と httpRequest が認識される。
import 'dart:convert';

import 'package:shelf/shelf.dart';

Middleware structuredLogger(void Function(String line) write) =>
    (inner) => (request) async {
          final watch = Stopwatch()..start();
          Response response;
          try {
            response = await inner(request);
          } catch (e, st) {
            write(jsonEncode({
              'severity': 'ERROR',
              'message': 'Unhandled error: $e',
              'stack_trace': st.toString(),
              'httpRequest': _httpRequest(request, 500, watch.elapsed),
            }));
            return Response.internalServerError(
              body: jsonEncode({
                'error': {'code': 'internal', 'message': 'サーバーでエラーが起きました'},
              }),
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          final status = response.statusCode;
          write(jsonEncode({
            'severity': status >= 500
                ? 'ERROR'
                : status >= 400
                    ? 'WARNING'
                    : 'INFO',
            'message': '${request.method} /${request.url.path} $status',
            'httpRequest': _httpRequest(request, status, watch.elapsed),
          }));
          return response;
        };

Map<String, Object?> _httpRequest(Request r, int status, Duration elapsed) => {
      'requestMethod': r.method,
      'requestUrl': r.requestedUri.toString(),
      'status': status,
      'userAgent': r.headers['user-agent'],
      'latency': '${(elapsed.inMicroseconds / 1e6).toStringAsFixed(6)}s',
    };

/// サーバー自体のログ（起動・停止など）
String serverLog(String message, {String severity = 'INFO'}) =>
    jsonEncode({'severity': severity, 'message': message});
