// bin/server.dart
//
// 起動：dart run bin/server.dart（backend/ で）
//   PORT           … 待ち受けるポート（既定 8080。Cloud Run が自動で渡す）
//   DATA_DIR       … profile.yaml / work.yaml / private.yaml を置いたフォルダー（既定 data）
//   ALLOWED_ORIGIN … ブラウザから直接呼ぶときに許す Origin（例 http://localhost:5000）。nginx 経由なら不要
//
// ヘルスチェック：server healthcheck（コンテナに curl がないので、自分で /healthz を確かめて終了コードを返す）
import 'dart:async';
import 'dart:io';

import 'package:portfolio_backend/portfolio_backend.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main(List<String> args) async {
  final env = Platform.environment;
  final port = int.tryParse(env['PORT'] ?? '') ?? 8080;

  if (args.contains('healthcheck')) {
    exit(await _healthcheck(port));
  }

  final dataDir = Directory(env['DATA_DIR'] ?? 'data');
  final handler = buildHandler(
    DataStore(dataDir),
    allowedOrigin: env['ALLOWED_ORIGIN'],
  );

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  server.autoCompress = true;
  stdout.writeln(serverLog(
      'Listening on :${server.port} (DATA_DIR=${dataDir.absolute.path})'));

  // Cloud Run・docker compose stop は SIGTERM を送るので、受けたら処理中のリクエストを終えてから止まる
  final signals = [
    ProcessSignal.sigint,
    if (!Platform.isWindows) ProcessSignal.sigterm,
  ];
  final stop = Completer<void>();
  final subs = [
    for (final s in signals)
      s.watch().listen((_) {
        if (!stop.isCompleted) stop.complete();
      }),
  ];
  await stop.future;
  for (final sub in subs) {
    await sub.cancel();
  }
  stdout.writeln(serverLog('Shutting down'));
  await server.close();
  exit(0);
}

Future<int> _healthcheck(int port) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
  try {
    final request = await client.get('127.0.0.1', port, '/healthz');
    final response = await request.close().timeout(const Duration(seconds: 3));
    await response.drain<void>();
    return response.statusCode == 200 ? 0 : 1;
  } catch (_) {
    return 1;
  } finally {
    client.close(force: true);
  }
}
