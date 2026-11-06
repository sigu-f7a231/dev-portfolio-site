// lib/widgets/tag_input_field.dart
//
// タグ（技術名など）を入力する欄（プロジェクトの入力フォームで使う）
// - 途中まで打つと、すでにある項目（[suggestions]）が入力欄の下に候補として出る。押すと、打ったのと同じくタグになる
//   （↑↓ で候補を選び Enter でも決められる。表記ゆれ・大文字小文字は気にせず探す）
// - カンマ（, 、 ，）か Enter で区切ると、それより前が 1 つのタグになる（日本語入力の変換中は区切らない）
// - 入力欄が空のときに Backspace を押すと、1 回目は直前のタグを強調し、2 回目でそのタグを消す
//   （タグの × でも消せる。スマホのキーボードは Backspace を送らないことがあるので × を使う）
// - 欄から離れたときに打ちかけの文字があれば、それもタグにする
// - 同じもの（表記ゆれを含む。lib/utils/skill_name.dart）は 2 つ入らない
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../theme/app_theme.dart';
import '../utils/skill_name.dart';

/// カンマ（, 、 ，）で分けたもの（前後の空白を除き、空は除く）
List<String> splitTags(String text) =>
    text.split(RegExp(r'[,、，]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

/// 入力したタグを持つ。[values] で、決まったタグと打ちかけの文字（カンマで分けたもの）をまとめて受け取る
class TagInputController extends ChangeNotifier {
  TagInputController({List<String> initial = const [], this.category}) : _tags = [...initial];

  /// クラウドのサービス（aws_services など）なら、先頭の AWS などを無視して同じものを見分ける
  final String? category;

  final List<String> _tags;
  String _pending = '';

  List<String> get tags => List.unmodifiable(_tags);

  /// 決まったタグ＋打ちかけの文字
  List<String> get values {
    final result = [..._tags];
    for (final t in splitTags(_pending)) {
      if (!_contains(result, t)) result.add(t);
    }
    return result;
  }

  bool _contains(List<String> list, String tag) {
    final k = skillKey(tag, category: category);
    return list.any((e) => skillKey(e, category: category) == k);
  }

  /// タグを足す（空・同じものがすでにあるときは足さない）。足したら true
  bool add(String raw) {
    final tag = cleanSkillName(raw);
    if (tag.isEmpty || _contains(_tags, tag)) return false;
    _tags.add(tag);
    notifyListeners();
    return true;
  }

  void removeAt(int index) {
    _tags.removeAt(index);
    notifyListeners();
  }

  /// 同じもの（表記ゆれを含む）を外す
  void remove(String tag) {
    final k = skillKey(tag, category: category);
    _tags.removeWhere((e) => skillKey(e, category: category) == k);
    notifyListeners();
  }

  /// 打ちかけの文字をタグにする（入力欄を閉じたあとに呼ぶ）
  void commitPending() {
    final text = _pending;
    _pending = '';
    for (final t in splitTags(text)) {
      add(t);
    }
  }

  /// すでにタグになっているか（候補から外すため）
  bool has(String tag) => _contains(_tags, tag);

  set pending(String text) => _pending = text;
}

class TagInputField extends StatefulWidget {
  final TagInputController controller;
  final String label;
  final String? hint;

  /// 候補（すでにある項目）
  final List<String> suggestions;

  const TagInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.suggestions = const [],
  });

  @override
  State<TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<TagInputField> {
  final _text = TextEditingController();
  late final FocusNode _focus = FocusNode(onKeyEvent: _onKey);

  /// Backspace を 1 回押して、直前のタグを消す前の強調をしているか
  bool _pendingDelete = false;

  /// ↑↓ で選んでいる候補の位置（選んでいなければ null）
  int? _highlight;

  /// 候補の数の上限
  static const int _maxOptions = 8;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onTextChanged);
    _focus.addListener(_onFocusChanged);
    widget.controller.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant TagInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_rebuild);
      widget.controller.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    // 閉じるときに打ちかけの文字は消さない（controller に残り、commitPending でタグにできる）
    _focus.removeListener(_onFocusChanged);
    _text.removeListener(_onTextChanged);
    widget.controller.removeListener(_rebuild);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// カンマが入ったら、それより前をタグにする（日本語入力の変換中は待つ）
  void _onTextChanged() {
    final value = _text.value;
    widget.controller.pending = value.text;
    // 文字が変わったら候補を出し直す（↑↓ の選択は外す）
    setState(() {
      _highlight = null;
      if (value.text.isNotEmpty) _pendingDelete = false;
    });
    if (value.composing.isValid) return;
    if (!value.text.contains(RegExp(r'[,、，]'))) return;

    final parts = value.text.split(RegExp(r'[,、，]'));
    final rest = parts.removeLast(); // 最後のカンマより後ろは打ちかけのまま
    for (final p in parts) {
      widget.controller.add(p);
    }
    _setText(rest.trimLeft());
  }

  void _setText(String text) {
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.controller.pending = text;
  }

  /// 打ちかけの文字をタグにする（Enter・欄から離れたとき）
  void _commit() {
    if (!mounted) return;
    final text = _text.text;
    if (text.trim().isEmpty) return;
    for (final t in splitTags(text)) {
      widget.controller.add(t);
    }
    _setText('');
  }

  void _onFocusChanged() {
    if (!_focus.hasFocus) {
      _commit();
      if (_pendingDelete) setState(() => _pendingDelete = false);
    }
  }

  /// 候補を選んでタグにする
  void _select(String option) {
    widget.controller.add(option);
    _setText('');
    setState(() => _highlight = null);
    _focus.requestFocus();
  }

  /// Enter：↑↓ で候補を選んでいればそれを、なければ打った文字をタグにする
  void _submit() {
    final options = _options(_text.value).toList();
    final h = _highlight;
    if (h != null && h < options.length) {
      _select(options[h]);
    } else {
      _commit();
    }
    _focus.requestFocus();
  }

  /// ↑↓：候補を選ぶ。入力欄が空のときの Backspace：1 回目は直前のタグを強調、2 回目で消す
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      final count = _options(_text.value).length;
      if (count == 0) return KeyEventResult.ignored;
      final down = key == LogicalKeyboardKey.arrowDown;
      setState(() {
        final h = _highlight;
        _highlight = h == null
            ? (down ? 0 : count - 1)
            : (h + (down ? 1 : -1)) % count;
        if (_highlight! < 0) _highlight = count - 1;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      if (_pendingDelete && event.logicalKey != LogicalKeyboardKey.shiftLeft) {
        setState(() => _pendingDelete = false);
      }
      return KeyEventResult.ignored;
    }
    if (_text.text.isNotEmpty || widget.controller.tags.isEmpty) return KeyEventResult.ignored;
    if (event is KeyRepeatEvent) return KeyEventResult.handled; // 押しっぱなしでまとめて消さない
    if (_pendingDelete) {
      widget.controller.removeAt(widget.controller.tags.length - 1);
      setState(() => _pendingDelete = false);
    } else {
      setState(() => _pendingDelete = true);
    }
    return KeyEventResult.handled;
  }

  /// 打った文字を含む候補（打った文字で始まるものを先に。すでにタグのものは除く）
  Iterable<String> _options(TextEditingValue value) {
    final typed = skillKey(value.text, category: widget.controller.category);
    if (typed.isEmpty) return const [];
    String key(String s) => skillKey(s, category: widget.controller.category);
    final hits = widget.suggestions
        .where((s) => !widget.controller.has(s) && key(s).contains(typed))
        .toList()
      ..sort((a, b) {
        final ap = key(a).startsWith(typed) ? 0 : 1;
        final bp = key(b).startsWith(typed) ? 0 : 1;
        return ap != bp ? ap - bp : a.length - b.length;
      });
    return hits.take(_maxOptions);
  }

  @override
  Widget build(BuildContext context) {
    final tags = widget.controller.tags;
    final scheme = context.colors.scheme;
    final options = _options(_text.value).toList();

    return InputDecorator(
      isFocused: _focus.hasFocus,
      isEmpty: false,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.space4),
              child: Wrap(
                spacing: AppSizes.space6,
                runSpacing: AppSizes.space6,
                children: [
                  for (var i = 0; i < tags.length; i++)
                    InputChip(
                      label: Text(tags[i]),
                      // Backspace 1 回目：消すタグを強調
                      selected: _pendingDelete && i == tags.length - 1,
                      showCheckmark: false,
                      selectedColor: scheme.errorContainer,
                      onSelected: (_) {},
                      onDeleted: () => widget.controller.removeAt(i),
                      deleteButtonTooltipMessage: AppTexts.filterRemoveTooltip(tags[i]),
                    ),
                ],
              ),
            ),
          TextField(
            controller: _text,
            focusNode: _focus,
            decoration: InputDecoration.collapsed(hintText: widget.hint),
            onSubmitted: (_) => _submit(),
            onEditingComplete: () {}, // Enter で欄から離れない
          ),
          // 候補（打った文字を含む、すでにある項目）。押すとタグになる
          if (options.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.space8),
              child: Wrap(
                spacing: AppSizes.space6,
                runSpacing: AppSizes.space6,
                children: [
                  for (final (i, o) in options.indexed)
                    ActionChip(
                      avatar: const Icon(Icons.add, size: AppSizes.space16),
                      label: Text(o),
                      // ↑↓ で選んでいる候補
                      backgroundColor: i == _highlight ? scheme.secondaryContainer : null,
                      onPressed: () => _select(o),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// 項目のボタンを押すと開く画面：入力欄（タグ入力）と、すでにある項目の一覧
/// - 一覧の項目を押すと入力欄に追加、もう一度押すと外す（入力欄と同じ [controller] を直接変える）
/// - 見出しと［完了］は固定し、本文だけスクロールする。スマホのキーボードが出ても隠れない
class TagPickerPanel extends StatelessWidget {
  final String title;
  final TagInputController controller;
  final List<String> suggestions;
  final VoidCallback onDone;

  const TagPickerPanel({
    super.key,
    required this.title,
    required this.controller,
    required this.suggestions,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      // スマホのキーボードの分だけ上げる
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.space24, AppSizes.space16, AppSizes.space8, AppSizes.space8),
            child: Row(
              children: [
                Expanded(child: Text(title, style: textTheme.titleLarge)),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: AppTexts.close,
                  onPressed: onDone,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.space24),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TagInputField(
                      controller: controller,
                      label: DataTexts.tagPickerInput,
                      hint: DataTexts.formListHint,
                      suggestions: suggestions,
                    ),
                    const SizedBox(height: AppSizes.space16),
                    Text(DataTexts.tagPickerExisting, style: textTheme.labelLarge),
                    const SizedBox(height: AppSizes.space8),
                    if (suggestions.isEmpty)
                      Text(DataTexts.tagPickerNoExisting, style: textTheme.bodySmall)
                    else
                      Wrap(
                        spacing: AppSizes.space8,
                        runSpacing: AppSizes.space8,
                        children: [
                          for (final s in suggestions)
                            FilterChip(
                              label: Text(s),
                              selected: controller.has(s),
                              onSelected: (v) {
                                if (v) {
                                  controller.add(s);
                                } else {
                                  controller.remove(s);
                                }
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSizes.space16),
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: onDone, child: const Text(DataTexts.tagPickerDone)),
            ),
          ),
        ],
      ),
    );
  }
}
