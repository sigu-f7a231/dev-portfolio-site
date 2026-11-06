// test/app_test.dart
//
// 実行：dart test（backend/ で）
import 'dart:convert';
import 'dart:io';

import 'package:portfolio_backend/portfolio_backend.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _profile = '''
home:
  name: 山田 太郎
  role: エンジニア
  tagline: |
    紹介文
about:
  intro: 自己紹介
''';

const _work = '''
projects:
  - title: 業務A
    workflow:
      - 詳細設計
    skills:
      - Dart
''';

const _private = '''
projects:
  - title: 個人B
    skills:
      - Dart
''';

void main() {
  late Directory dir;
  late Handler handler;
  final logs = <String>[];

  void write(String name, String body) =>
      File('${dir.path}/$name.yaml').writeAsStringSync(body);

  Future<Response> get(String path) async =>
      await handler(Request('GET', Uri.parse('http://localhost$path')));

  Future<Map<String, dynamic>> body(Response r) async =>
      jsonDecode(await r.readAsString()) as Map<String, dynamic>;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('portfolio_backend_test');
    write('profile', _profile);
    write('work', _work);
    write('private', _private);
    logs.clear();
    handler = buildHandler(DataStore(dir), log: logs.add);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('/healthz は 200 でキャッシュしない', () async {
    final r = await get('/healthz');
    expect(r.statusCode, 200);
    expect(await body(r), {'status': 'ok'});
    expect(r.headers['cache-control'], 'no-store');
  });

  test('/api/profile はプロフィールを JSON で返す', () async {
    final r = await get('/api/profile');
    expect(r.statusCode, 200);
    expect(r.headers['content-type'], startsWith('application/json'));
    final b = await body(r);
    expect(b['home']['name'], '山田 太郎');
    expect(b['home']['tagline'], '紹介文\n');
  });

  test('/api/projects/work と /api/projects/private', () async {
    final w = await body(await get('/api/projects/work'));
    expect(w['projects'][0]['title'], '業務A');
    final p = await body(await get('/api/projects/private'));
    expect(p['projects'][0]['title'], '個人B');
  });

  test('知らない type は 404', () async {
    final r = await get('/api/projects/other');
    expect(r.statusCode, 404);
    expect((await body(r))['error']['code'], 'unknown_type');
  });

  test('知らないパスは 404', () async {
    final r = await get('/nothing');
    expect(r.statusCode, 404);
    expect((await body(r))['error']['code'], 'not_found');
  });

  test('ファイルがなければ 404（data_not_found）', () async {
    File('${dir.path}/work.yaml').deleteSync();
    final r = await get('/api/projects/work');
    expect(r.statusCode, 404);
    expect((await body(r))['error']['code'], 'data_not_found');
  });

  test('Work に workflow がなければ 500（invalid_data）', () async {
    write('work', _private);
    final r = await get('/api/projects/work');
    expect(r.statusCode, 500);
    expect((await body(r))['error']['code'], 'invalid_data');
  });

  test('Private に workflow があれば 500（invalid_data）', () async {
    write('private', _work);
    final r = await get('/api/projects/private');
    expect(r.statusCode, 500);
  });

  test('プロフィールの必須項目がなければ 500', () async {
    write('profile', 'home:\n  name: 太郎\nabout:\n  intro: 自己紹介\n');
    final r = await get('/api/profile');
    expect(r.statusCode, 500);
    expect((await body(r))['error']['message'], contains('home.role'));
  });

  test('YAML の書き方の誤りは 500', () async {
    write('work', 'projects: [\n');
    final r = await get('/api/projects/work');
    expect(r.statusCode, 500);
  });

  test('ログは 1 リクエスト 1 行の JSON（severity と httpRequest）', () async {
    await get('/healthz');
    await get('/nothing');
    expect(logs, hasLength(2));
    final ok = jsonDecode(logs[0]) as Map<String, dynamic>;
    expect(ok['severity'], 'INFO');
    expect(ok['httpRequest']['status'], 200);
    expect(ok['httpRequest']['latency'], endsWith('s'));
    expect((jsonDecode(logs[1]) as Map)['severity'], 'WARNING');
  });

  test('ALLOWED_ORIGIN を渡すと CORS のヘッダーが付く', () async {
    handler = buildHandler(DataStore(dir),
        allowedOrigin: 'http://localhost:5000', log: logs.add);
    final r = await get('/api/profile');
    expect(r.headers['access-control-allow-origin'], 'http://localhost:5000');
  });
}
