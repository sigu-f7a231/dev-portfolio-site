// lib/models/profile.dart
//
// プロフィール（Home と About に表示する内容）
// YAML の形は assets/data/format_profile.yaml を参照
import 'package:yaml/yaml.dart';
import '../constants/app_texts.dart';

class Profile {
  // ---------- Home ----------
  final String name;
  final String role;
  final String tagline;

  /// 右側のカード。値は `String` か `List<String>`
  final Map<String, Object> card;

  // ---------- About ----------
  final String intro;
  final List<String> domains;
  final String strengths;
  final String style;
  final String closing;

  /// 直近 / 過去の開発経験（複数行。スキルシートの Excel から読み込んだときに入る）
  final String recent;
  final String past;

  /// 直近 / 過去の主な技術（分類 → 技術）
  final Map<String, List<String>> recentTech;
  final Map<String, List<String>> pastTech;

  const Profile({
    required this.name,
    required this.role,
    required this.tagline,
    this.card = const {},
    required this.intro,
    this.domains = const [],
    this.strengths = '',
    this.style = '',
    this.closing = '',
    this.recent = '',
    this.past = '',
    this.recentTech = const {},
    this.pastTech = const {},
  });

  /// まだ読み込んでいないとき（入力画面の後ろに出す空の表示）
  static const Profile empty = Profile(name: '', role: '', tagline: '', intro: '');

  // YAML で使えるキー
  static const _topKeys = {'home', 'about'};
  static const _homeKeys = {'name', 'role', 'tagline', 'card'};
  static const _aboutKeys = {
    'intro', 'domains', 'strengths', 'style', 'closing',
    'recent', 'recent_tech', 'past', 'past_tech',
  };

  /// YAML の文字列を読み取る。形式が違うときは errors に理由を入れて返す（profile は null）
  static ProfileParseResult parse(String text) {
    final errors = <String>[];

    Object? doc;
    try {
      doc = loadYaml(text);
    } on YamlException catch (e) {
      return ProfileParseResult.error([ProfileTexts.errorSyntax(e.message)]);
    }
    if (doc is! YamlMap) {
      return ProfileParseResult.error([ProfileTexts.errorNotMap]);
    }

    // 知らないキー（Work / Private の YAML を間違えて選んだ場合など）
    for (final k in doc.keys) {
      if (!_topKeys.contains(k)) errors.add(ProfileTexts.errorUnknownKey('$k'));
    }

    final home = doc['home'];
    final about = doc['about'];
    if (home is! YamlMap) errors.add(ProfileTexts.errorMissingSection('home'));
    if (about is! YamlMap) errors.add(ProfileTexts.errorMissingSection('about'));
    if (home is! YamlMap || about is! YamlMap) return ProfileParseResult.error(errors);

    for (final k in home.keys) {
      if (!_homeKeys.contains(k)) errors.add(ProfileTexts.errorUnknownKey('home.$k'));
    }
    for (final k in about.keys) {
      if (!_aboutKeys.contains(k)) errors.add(ProfileTexts.errorUnknownKey('about.$k'));
    }

    String text_(YamlMap m, String section, String key, {bool required = false}) {
      final v = m[key];
      if (v == null) {
        if (required) errors.add(ProfileTexts.errorRequired('$section.$key'));
        return '';
      }
      if (v is YamlMap || v is YamlList) {
        errors.add(ProfileTexts.errorNotText('$section.$key'));
        return '';
      }
      final s = '$v'.trim();
      if (required && s.isEmpty) errors.add(ProfileTexts.errorRequired('$section.$key'));
      return s;
    }

    List<String> list_(YamlMap m, String section, String key) {
      final v = m[key];
      if (v == null) return const [];
      if (v is! YamlList) {
        errors.add(ProfileTexts.errorNotList('$section.$key'));
        return const [];
      }
      return v.where((e) => e != null).map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
    }

    /// 「分類: のあとに - 箇条書き」（1 つだけなら「分類: 値」でもよい）
    Map<String, List<String>> groups_(YamlMap m, String section, String key) {
      final v = m[key];
      if (v == null) return const {};
      if (v is! YamlMap) {
        errors.add(ProfileTexts.errorNotMapField('$section.$key'));
        return const {};
      }
      final result = <String, List<String>>{};
      v.forEach((k, items) {
        if (items is YamlMap) {
          errors.add(ProfileTexts.errorCardValue('$section.$key.$k'));
        } else if (items is YamlList) {
          result['$k'] = items.where((e) => e != null).map((e) => '$e'.trim()).where((e) => e.isNotEmpty).toList();
        } else if (items != null && '$items'.trim().isNotEmpty) {
          result['$k'] = ['$items'.trim()];
        }
      });
      return result;
    }

    final card = <String, Object>{};
    final rawCard = home['card'];
    if (rawCard != null) {
      if (rawCard is! YamlMap) {
        errors.add(ProfileTexts.errorNotMapField('home.card'));
      } else {
        rawCard.forEach((k, v) {
          if (v is YamlList) {
            card['$k'] = v.map((e) => '$e').toList();
          } else if (v is YamlMap) {
            errors.add(ProfileTexts.errorCardValue('home.card.$k'));
          } else {
            card['$k'] = v == null ? '' : '$v';
          }
        });
      }
    }

    final profile = Profile(
      name: text_(home, 'home', 'name', required: true),
      role: text_(home, 'home', 'role', required: true),
      tagline: text_(home, 'home', 'tagline', required: true),
      card: card,
      intro: text_(about, 'about', 'intro', required: true),
      domains: list_(about, 'about', 'domains'),
      strengths: text_(about, 'about', 'strengths'),
      style: text_(about, 'about', 'style'),
      closing: text_(about, 'about', 'closing'),
      recent: text_(about, 'about', 'recent'),
      past: text_(about, 'about', 'past'),
      recentTech: groups_(about, 'about', 'recent_tech'),
      pastTech: groups_(about, 'about', 'past_tech'),
    );

    return errors.isEmpty ? ProfileParseResult.ok(profile) : ProfileParseResult.error(errors);
  }
}

class ProfileParseResult {
  final Profile? profile;
  final List<String> errors;

  const ProfileParseResult.ok(Profile this.profile) : errors = const [];
  const ProfileParseResult.error(this.errors) : profile = null;

  bool get isOk => profile != null;
}
