// lib/utils/data_format.dart
//
// アップロード・起動時に読み込むデータの形式（YAML / Markdown）をそろえる
// - YAML はそのまま使う
// - Markdown は決まった書き方（assets/data/format_*.md）を読み取り、同じ中身の JSON 文字列に変える
//   （JSON は YAML の一種なので、その後の検証・保存・表示は YAML と同じ処理がそのまま使える）
//
// Flutter に依存しない（dart run tool/run.dart からも使う）。
import 'dart:convert';

import 'package:yaml/yaml.dart';

import '../constants/app_texts.dart';
import 'language_utils.dart';

enum DataFormat { yaml, markdown }

/// 何のデータか（Markdown の読み方が変わる）
enum DataKind { work, private, profile }

/// テンプレート（assets/data/format_*.yaml / .md）のファイル名
String templateFileName(DataKind kind, DataFormat format) =>
    'format_${kind.name}.${format == DataFormat.markdown ? 'md' : 'yaml'}';

String templateAssetPath(DataKind kind, DataFormat format) =>
    'assets/data/${templateFileName(kind, format)}';

/// 複数件まとめて追加するときのサンプル（Work / Private。2 件以上入っている）の場所
/// テンプレート（format_*）は 1 件のまま（ほかのテンプレートと中身をそろえるため）、こちらは別に持つ
String multiSampleAssetPath(DataKind kind, DataFormat format) =>
    'assets/data/sample_${kind.name}_multi.${format == DataFormat.markdown ? 'md' : 'yaml'}';

/// 'work' / 'private' → DataKind
DataKind projectKind(String dataType) =>
    dataType == 'work' ? DataKind.work : DataKind.private;

/// ファイル選択で選べる拡張子
const List<String> acceptedExtensions = ['yaml', 'yml', 'md', 'markdown'];

bool hasAcceptedExtension(String fileName) {
  final lower = fileName.toLowerCase();
  return acceptedExtensions.any((e) => lower.endsWith('.$e'));
}

/// 読み込んだテキストを YAML として扱える形にした結果
class NormalizedData {
  /// YAML として読めるテキスト（YAML はそのまま、Markdown は JSON）。読み取れなかったときは null
  final String? text;
  final DataFormat format;

  /// Markdown の書き方の誤り（YAML のときは空。中身の検証は呼び出し側で行う）
  final List<String> errors;

  const NormalizedData(this.text, this.format, this.errors);
}

/// テキストの形式を見分けて、YAML として扱える形にする
/// - [fileName] の拡張子（.md / .markdown / .yaml / .yml）があればそれに従う
/// - 貼り付けなど拡張子がないときは、YAML の「キー: 値」として読めれば YAML、
///   読めなくて「# 見出し」があれば Markdown とみなす
NormalizedData normalizeInput(String raw, {required DataKind kind, String? fileName}) {
  final format = detectFormat(raw, fileName: fileName);
  if (format == DataFormat.yaml) return NormalizedData(raw, DataFormat.yaml, const []);

  final lines = _lines(raw);
  final result = kind == DataKind.profile ? _profileFromLines(lines) : _projectsFromLines(lines);
  if (result.errors.isNotEmpty) return NormalizedData(null, DataFormat.markdown, result.errors);
  return NormalizedData(jsonEncode(result.data), DataFormat.markdown, const []);
}

DataFormat detectFormat(String raw, {String? fileName}) {
  final name = fileName?.toLowerCase();
  if (name != null) {
    if (name.endsWith('.md') || name.endsWith('.markdown')) return DataFormat.markdown;
    if (name.endsWith('.yaml') || name.endsWith('.yml')) return DataFormat.yaml;
  }
  try {
    if (loadYaml(raw) is YamlMap) return DataFormat.yaml;
  } catch (_) {
    // YAML として読めない → 下で Markdown かを見る
  }
  // 書き間違いのある YAML（「projects:」「home:」など行頭の「キー:」がある）は YAML のまま扱い、YAML のエラーを出す
  //（YAML のコメント「# ----」が Markdown の見出しに見えるため）
  final lines = _lines(raw);
  if (lines.any((l) => _yamlTopKey.hasMatch(l))) return DataFormat.yaml;
  final hasHeading = lines.any((l) => _h1.hasMatch(l));
  return hasHeading ? DataFormat.markdown : DataFormat.yaml; // どちらでもなければ YAML のエラーを出す
}

// ------------------------------------------------------------
// Markdown の読み取り
// ------------------------------------------------------------
/// 「#」が [level] 個ちょうどの見出し（それより深い見出しには当てはまらない）
RegExp _heading(int level) => RegExp('^#{$level}(?!#)\\s+(.+?)\\s*#*\\s*\$');
final _h1 = _heading(1);
final _field = RegExp(r'^\s*[-*+]\s+([A-Za-z_][A-Za-z0-9_]*)\s*[:：]\s*(.*)$');
final _bullet = RegExp(r'^\s*[-*+]\s+(.*)$');
final _yamlTopKey = RegExp(r'^[A-Za-z_][A-Za-z0-9_]*\s*:(\s|$)');

/// コメント（<!-- -->）とコードブロックの囲み（```）を空行にした行
/// （消すのではなく空行にして、エラーの行番号を元のファイルの行番号のままにする）
List<String> _lines(String raw) => raw
    .replaceAll('\r\n', '\n')
    .replaceAllMapped(
      RegExp(r'<!--[\s\S]*?-->'),
      (m) => '\n' * '\n'.allMatches(m[0]!).length, // コメントの中の改行の数だけ残す
    )
    .split('\n')
    .map((l) => l.trimLeft().startsWith('```') ? '' : l)
    .toList();

/// 「# 見出し」ごとのまとまり
class _Block {
  final String heading;
  final int line; // エラー表示用（1 始まり）
  final List<(String, String, int)> fields = []; // キー・値・行番号
  final List<(String, List<String>, int)> subs = []; // ## 見出し・中身の行・行番号
  final List<(String, int)> stray = []; // どれにも当てはまらない行

  _Block(this.heading, this.line);
}

/// [lines] を「見出し（深さ [level]）」ごとのまとまりに分ける。
/// 行番号は [lines] の位置（1 始まり）。ほかの区切りの行は空行にして渡すと、元のファイルの行番号のまま知らせられる
({List<_Block> blocks, List<String> errors}) _parseBlocks(List<String> lines, {int level = 1}) {
  final blocks = <_Block>[];
  final errors = <String>[];
  final blockHeading = _heading(level);
  final subHeading = _heading(level + 1);

  _Block? current;
  (String, List<String>, int)? sub;

  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final no = i + 1;
    final h2 = subHeading.firstMatch(line);
    final h1 = h2 == null ? blockHeading.firstMatch(line) : null;

    if (h1 != null) {
      current = _Block(h1.group(1)!.trim(), no);
      blocks.add(current);
      sub = null;
      continue;
    }
    if (line.trim().isEmpty) {
      sub?.$2.add('');
      continue;
    }
    if (current == null) {
      errors.add(MarkdownTexts.beforeFirstHeading(no, line.trim()));
      continue;
    }
    if (h2 != null) {
      sub = (h2.group(1)!.trim(), <String>[], no);
      current.subs.add(sub);
      continue;
    }
    if (sub != null) {
      sub.$2.add(line);
      continue;
    }
    final f = _field.firstMatch(line);
    if (f != null) {
      current.fields.add((f.group(1)!.toLowerCase(), f.group(2)!.trim(), no));
    } else {
      current.stray.add((line.trim(), no));
    }
  }
  for (final b in blocks) {
    for (final (text, no) in b.stray) {
      errors.add(MarkdownTexts.strayLine(no, text));
    }
  }
  return (blocks: blocks, errors: errors);
}

/// カンマ（, ・、）区切りを分ける
List<String> _splitList(String v, {bool japaneseComma = true}) => v
    .split(japaneseComma ? RegExp(r'[,、]') : RegExp(r','))
    .map((e) => e.trim())
    .where((e) => e.isNotEmpty)
    .toList();

/// 「## 見出し」の中身（前後の空行を除き、行をつなぐ）
String _subText(List<String> lines) {
  final text = lines.join('\n').trim();
  return text;
}

// ---------- Work / Private ----------
const _projectListKeys = {
  'server_os', 'db', 'tools', 'backend_frameworks', 'frontend_frameworks', 'ui_frameworks',
  'testing_frameworks', 'cloud_platforms', 'aws_services', 'azure_services', 'gcp_services',
  'container', 'container_orchestration', 'ai_services', 'skills',
};
const _projectTextKeys = {'description', 'link', 'details'};

({Map<String, Object> data, List<String> errors}) _projectsFromLines(List<String> lines, {int level = 1}) {
  final parsed = _parseBlocks(lines, level: level);
  final errors = [...parsed.errors];
  if (parsed.blocks.isEmpty) {
    return (data: const {}, errors: [...errors, MarkdownTexts.noProjects]);
  }

  final ja = LanguageUtils.workflowLabels['ja']!; // キー → 日本語
  final jaToKey = {for (final e in ja.entries) e.value: e.key};

  final projects = <Map<String, Object>>[];
  for (final b in parsed.blocks) {
    final p = <String, Object>{'title': b.heading};
    for (final (key, value, no) in b.fields) {
      if (key == 'period') {
        p['period'] = value
            .split(RegExp(r'\s*(?:~|〜|～|→|\s-\s)\s*'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (key == 'workflow') {
        final steps = <String, bool>{for (final k in ja.keys) k: false};
        for (final s in _splitList(value)) {
          final k = ja.containsKey(s) ? s : jaToKey[s];
          if (k == null) {
            errors.add(MarkdownTexts.unknownWorkflow(no, s));
          } else {
            steps[k] = true;
          }
        }
        p['workflow'] = steps;
      } else if (_projectListKeys.contains(key)) {
        p[key] = _splitList(value);
      } else if (_projectTextKeys.contains(key)) {
        p[key] = value;
      } else {
        errors.add(MarkdownTexts.unknownKey(no, key));
      }
    }
    for (final (name, lines, no) in b.subs) {
      final key = name.toLowerCase();
      if (key == 'details' || name == AppTexts.fieldDetails) {
        p['details'] = _subText(lines);
      } else {
        errors.add(MarkdownTexts.unknownSection(no, name));
      }
    }
    projects.add(p);
  }
  return (data: {'projects': projects}, errors: errors);
}

// ---------- プロフィール ----------
const _profileListKeys = {'domains'};
const _profileMapKeys = {'card'};

({Map<String, Object> data, List<String> errors}) _profileFromLines(List<String> lines) {
  final parsed = _parseBlocks(lines);
  final errors = [...parsed.errors];
  if (parsed.blocks.isEmpty) {
    return (data: const {}, errors: [...errors, MarkdownTexts.noProfileSections]);
  }

  final data = <String, Object>{};
  for (final b in parsed.blocks) {
    // 見出しは home / about（大文字・小文字は問わない）。それ以外は Profile.parse が「使えない項目」として知らせる
    final section = b.heading.toLowerCase();
    final m = <String, Object>{};
    for (final (key, value, _) in b.fields) {
      m[key] = _profileListKeys.contains(key) ? _splitList(value) : value;
    }
    for (final (name, lines, no) in b.subs) {
      final key = name.toLowerCase();
      final body = lines.where((l) => l.trim().isNotEmpty).toList();
      final isMap = body.isNotEmpty && body.every((l) => _field.hasMatch(l));
      if (_profileMapKeys.contains(key) || (isMap && !_profileListKeys.contains(key))) {
        if (!isMap) {
          errors.add(MarkdownTexts.cardNeedsFields(no, name));
          continue;
        }
        // 「- キー: 値」の並び（カンマ区切りは箇条書き）
        m[key] = {
          for (final l in body)
            _field.firstMatch(l)!.group(1)!: () {
              final v = _field.firstMatch(l)!.group(2)!.trim();
              final parts = _splitList(v, japaneseComma: false);
              return parts.length > 1 ? parts : v;
            }(),
        };
      } else if (_profileListKeys.contains(key) || body.every((l) => _bullet.hasMatch(l))) {
        m[key] = body.map((l) => _bullet.firstMatch(l)?.group(1)?.trim() ?? l.trim()).toList();
      } else {
        m[key] = _subText(lines);
      }
    }
    data[section] = m;
  }
  return (data: data, errors: errors);
}

// ------------------------------------------------------------
// プロフィール＋Work / Private（最初の入力画面で 1 回にまとめて読み込む）
// ------------------------------------------------------------
/// プロフィールのファイルに一緒に書ける区切り
const bundleSections = ['work', 'private'];

/// プロフィールのファイルを、プロフィール・Work・Private に分けた結果
class ProfileBundleData {
  /// プロフィール（home / about）。YAML として読めるテキスト
  final NormalizedData profile;

  /// 書かれていたときだけ入る（{"projects": [...]} の JSON＝YAML として読める）
  final String? work;
  final String? private;

  const ProfileBundleData(this.profile, {this.work, this.private});
}

/// プロフィールのファイルを読み、work / private が一緒に書かれていれば分ける
/// - YAML：トップに `work:` / `private:`（プロジェクトの並び、または `projects:` を持つ形）
/// - Markdown：`# work` / `# private` の見出しの下に、1 件ごとに `## プロジェクト名`、詳細は `### details`
///   （単独の Work / Private ファイルより見出しが 1 段深い）
ProfileBundleData normalizeProfileBundle(String raw, {String? fileName}) {
  final format = detectFormat(raw, fileName: fileName);
  return format == DataFormat.markdown ? _bundleFromMarkdown(raw) : _bundleFromYaml(raw);
}

ProfileBundleData _bundleFromYaml(String raw) {
  Object? doc;
  try {
    doc = loadYaml(raw);
  } catch (_) {
    // 書き方の誤りは、プロフィールの検証（Profile.parse）で知らせる
    return ProfileBundleData(NormalizedData(raw, DataFormat.yaml, const []));
  }
  if (doc is! YamlMap || !bundleSections.any(doc.containsKey)) {
    return ProfileBundleData(NormalizedData(raw, DataFormat.yaml, const []));
  }

  final YamlMap map = doc;
  final errors = <String>[];
  String? projects(String key) {
    if (!map.containsKey(key)) return null;
    final node = map[key];
    if (node is YamlList) return jsonEncode({'projects': node});
    if (node is YamlMap && node['projects'] is YamlList) return jsonEncode(node);
    errors.add(BundleTexts.notProjects(key));
    return null;
  }

  final work = projects('work');
  final private = projects('private');
  // プロフィール部分だけを取り出す（work / private 以外のキーはそのまま。知らないキーは Profile.parse が知らせる）
  final profileOnly = {
    for (final e in map.entries)
      if (!bundleSections.contains(e.key)) '${e.key}': e.value,
  };
  return ProfileBundleData(
    NormalizedData(errors.isEmpty ? jsonEncode(profileOnly) : null, DataFormat.yaml, errors),
    work: work,
    private: private,
  );
}

ProfileBundleData _bundleFromMarkdown(String raw) {
  final lines = _lines(raw);

  // 「# 見出し」ごとの範囲 → work / private の区切りを見つける
  final sections = <String, (int, int)>{}; // 名前 → (見出しの行, 次の見出しの行)
  int? start;
  String? name;
  for (var i = 0; i <= lines.length; i++) {
    final h = i < lines.length ? _h1.firstMatch(lines[i]) : null;
    if (h == null && i < lines.length) continue;
    if (name != null && bundleSections.contains(name)) sections[name] = (start!, i);
    if (h != null) {
      start = i;
      name = h.group(1)!.trim().toLowerCase();
    }
  }

  // それぞれの区切りだけを残し、ほかは空行にする（行番号を元のファイルのままにするため）
  List<String> only(bool Function(int i) keep) =>
      [for (var i = 0; i < lines.length; i++) keep(i) ? lines[i] : ''];
  bool inBundle(int i) => sections.values.any((r) => i >= r.$1 && i < r.$2);

  final errors = <String>[];
  final profile = _profileFromLines(only((i) => !inBundle(i)));
  errors.addAll(profile.errors);

  String? projects(String key) {
    final r = sections[key];
    if (r == null) return null;
    // 見出しの行（# work）は外し、その下を「## プロジェクト名」として読む
    final result = _projectsFromLines(only((i) => i > r.$1 && i < r.$2), level: 2);
    errors.addAll(result.errors.map((e) => e == MarkdownTexts.noProjects ? BundleTexts.noProjectsIn(key) : e));
    return result.errors.isEmpty ? jsonEncode(result.data) : null;
  }

  final work = projects('work');
  final private = projects('private');
  return ProfileBundleData(
    NormalizedData(errors.isEmpty ? jsonEncode(profile.data) : null, DataFormat.markdown, errors),
    work: work,
    private: private,
  );
}

