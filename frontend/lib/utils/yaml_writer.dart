// lib/utils/yaml_writer.dart
//
// Map / List / 文字列を、人が読み書きしやすい YAML の文字列にする（Excel から作ったプロフィールの保存用）
// - インデントは半角スペース 2 つ（テンプレートと同じ）
// - 複数行の文章は「|-」のブロック、記号などで誤読されうる文字列は "…" で囲む
//
// Flutter に依存しない（dart run tool/run.dart からも使う）。
import 'dart:convert';

/// [data] を YAML にする。[header] は先頭に「# 」付きで入れるコメント（複数行可）
String toYaml(Map<String, Object?> data, {String? header}) {
  final buffer = StringBuffer();
  if (header != null) {
    for (final line in header.split('\n')) {
      buffer.writeln(line.isEmpty ? '#' : '# $line');
    }
    buffer.writeln();
  }
  _writeMap(buffer, data, 0);
  return buffer.toString();
}

void _writeMap(StringBuffer b, Map<String, Object?> map, int indent) {
  final pad = ' ' * indent;
  for (final e in map.entries) {
    final key = _scalar(e.key);
    final v = e.value;
    if (v is Map && v.isNotEmpty) {
      b.writeln('$pad$key:');
      _writeMap(b, v.map((k, v) => MapEntry('$k', v)), indent + 2);
    } else if (v is List && v.isNotEmpty) {
      b.writeln('$pad$key:');
      _writeList(b, v, indent + 2);
    } else if (v is String && _isBlock(v)) {
      b.writeln('$pad$key: |-');
      _writeBlock(b, v, indent + 2);
    } else {
      b.writeln('$pad$key: ${_inline(v)}');
    }
  }
}

void _writeList(StringBuffer b, List<Object?> list, int indent) {
  final pad = ' ' * indent;
  for (final v in list) {
    if (v is Map && v.isNotEmpty) {
      // 「- 」のあとに最初のキーを続ける（2 つ目以降のキーは「- 」の分だけ下げる）
      final inner = StringBuffer();
      _writeMap(inner, v.map((k, v) => MapEntry('$k', v)), indent + 2);
      final text = inner.toString();
      b.write('$pad- ${text.substring(indent + 2)}');
    } else if (v is List && v.isNotEmpty) {
      b.writeln('$pad-');
      _writeList(b, v, indent + 2);
    } else if (v is String && _isBlock(v)) {
      b.writeln('$pad- |-');
      _writeBlock(b, v, indent + 2);
    } else {
      b.writeln('$pad- ${_inline(v)}');
    }
  }
}

void _writeBlock(StringBuffer b, String text, int indent) {
  final pad = ' ' * indent;
  for (final line in text.split('\n')) {
    b.writeln(line.isEmpty ? '' : '$pad$line');
  }
}

/// 「|-」のブロックで書けるか（複数行で、1 行目が空白で始まらず、制御文字がない）
bool _isBlock(String s) =>
    s.contains('\n') &&
    !s.startsWith(' ') &&
    !s.startsWith('\n') &&
    !s.endsWith('\n') &&
    !s.contains('\t') &&
    !_control.hasMatch(s.replaceAll('\n', ''));

final _control = RegExp(r'[\x00-\x1F\x7F]');

String _inline(Object? v) {
  if (v == null) return '""';
  if (v is bool || v is num) return '$v';
  if (v is Map) return '{}';
  if (v is List) return '[]';
  return _scalar('$v');
}

/// 文字列をそのまま書いてよいか。だめなら JSON の文字列（＝YAML のダブルクォート）にする
String _scalar(String s) => _isPlain(s) ? s : jsonEncode(s);

// 先頭は文字・「_」・括弧だけ（数字・記号で始まると数値や YAML の記号として読まれうる）
final _plainStart = RegExp(r'^[\p{L}_（(]', unicode: true);
final _reserved = RegExp(r'^(true|false|yes|no|on|off|null|y|n)$', caseSensitive: false);

bool _isPlain(String s) =>
    s.isNotEmpty &&
    _plainStart.hasMatch(s) &&
    s.trim() == s &&
    !s.contains(': ') &&
    !s.contains(' #') &&
    !s.endsWith(':') &&
    !_control.hasMatch(s) &&
    !_reserved.hasMatch(s);
