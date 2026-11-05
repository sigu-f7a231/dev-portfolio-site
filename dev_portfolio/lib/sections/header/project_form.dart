// lib/sections/header/project_form.dart
//
// プロジェクト 1 件分の入力フォーム（ヘッダーの［データ］→ 追加 → 画面上で入力 → 1 件 → 入力フォーム）
// - プロジェクト名だけ必須。期間は欄を押すと開く年月の選択（Material 3 の日付選択と同じ見た目）で選ぶ。進行中なら終わりは「現在」
// - 技術は項目ごとの小さなボタン。押すと入力欄とすでにある項目の一覧が開く（TagPickerPanel。一覧を押すと追加）。
//   入力欄はタグ入力（lib/widgets/tag_input_field.dart）：途中まで打つと、すでにある項目が候補に出る。
//   カンマか Enter で区切る。空の欄で Backspace 1 回目で直前を強調、2 回目で消す。空なら「利用なし」として保存する
// - Work だけ「担当した工程」（workflow）を選ぶ
// - 入力した内容は [ProjectFormState.collect] で、YAML と同じ形の Map にして受け取る（正しくなければ null）
import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';
import '../../theme/app_styles.dart';
import '../../utils/language_utils.dart';
import '../../utils/skill_name.dart';
import '../../utils/tech_catalog.dart';
import '../../widgets/app_filter_modal.dart';
import '../../widgets/tag_input_field.dart';
import '../../widgets/year_month_picker.dart';

/// 技術の項目（YAML のキー）。上の 6 つはいつも出し、残りは「そのほかの技術」にまとめる
/// Skills・Tools 以外の技術の項目
const _otherListKeys = [
  'frontend_frameworks', 'backend_frameworks', 'ui_frameworks', 'testing_frameworks', 'db',
  'server_os', 'cloud_platforms', 'aws_services', 'azure_services', 'gcp_services', 'container',
  'container_orchestration', 'ai_services',
];

/// Skills・Tools はグループ（Skills のグラフ・フィルター・詳細と同じ分け方）ごとに入れ、保存のときに 1 つにまとめる
final _skillGroupKeys = [for (final g in SkillGroup.values) g.key];
final _toolGroupKeys = [for (final g in ToolGroup.values) g.key];
final _allInputKeys = [..._skillGroupKeys, ..._toolGroupKeys, ..._otherListKeys];

/// 入力の欄のキー → 同じものを見分けるときの分類（Skills・Tools のグループはまとめて 1 つ）
String _categoryOf(String key) =>
    _skillGroupKeys.contains(key) ? 'skills' : (_toolGroupKeys.contains(key) ? 'tools' : key);

class ProjectForm extends StatefulWidget {
  final bool isWork;

  /// 技術の候補（項目のキー → すでにある項目）
  final Map<String, List<String>> suggestions;

  const ProjectForm({super.key, required this.isWork, this.suggestions = const {}});

  @override
  State<ProjectForm> createState() => ProjectFormState();
}

class ProjectFormState extends State<ProjectForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _details = TextEditingController();
  final _start = TextEditingController();
  final _end = TextEditingController();
  final _link = TextEditingController();
  final Map<String, TagInputController> _lists = {
    for (final k in _allInputKeys) k: TagInputController(category: _categoryOf(k)),
  };
  bool _ongoing = false;

  /// 担当した工程（Work のみ）。キーは YAML の workflow のキー
  final Map<String, bool> _workflow = {
    for (final k in LanguageUtils.workflowLabels['ja']!.keys) k: false,
  };

  @override
  void dispose() {
    for (final c in [_title, _description, _details, _start, _end, _link]) {
      c.dispose();
    }
    for (final c in _lists.values) {
      c.dispose();
    }
    super.dispose();
  }

  static final _yearMonth = RegExp(r'^(\d{4})\s*[-/.年]\s*(\d{1,2})月?$');

  /// 「2024-04」「2024/4」「２０２４年４月」→「2024-04」（読めなければ null）
  static String? normalizeYearMonth(String raw) {
    final m = _yearMonth.firstMatch(toHalfWidth(raw).trim());
    if (m == null) return null;
    final month = int.parse(m.group(2)!);
    if (month < 1 || month > 12) return null;
    return '${m.group(1)}-${'$month'.padLeft(2, '0')}';
  }

  String? _validateStart(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) {
      return _end.text.trim().isNotEmpty || _ongoing ? DataTexts.formPeriodStartMissing : null;
    }
    return normalizeYearMonth(s) == null ? DataTexts.formPeriodInvalid : null;
  }

  String? _validateEnd(String? v) {
    if (_ongoing) return null;
    final s = (v ?? '').trim();
    final start = normalizeYearMonth(_start.text);
    if (s.isEmpty) return start != null ? DataTexts.formPeriodEndMissing : null;
    final end = normalizeYearMonth(s);
    if (end == null) return DataTexts.formPeriodInvalid;
    if (start != null && end.compareTo(start) < 0) return DataTexts.formPeriodOrder;
    return null;
  }

  /// 入力を確かめて、YAML と同じ形の Map にする（正しくなければエラーを出して null）
  Map<String, dynamic>? collect() {
    if (!(_formKey.currentState?.validate() ?? false)) return null;
    // 決まったタグ＋打ちかけの文字。空なら「利用なし」
    List<String> orNotUsed(List<String> items) => items.isEmpty ? const [ExcelTexts.notUsed] : items;
    List<String> list(String key) => orNotUsed(_lists[key]!.values);

    /// グループごとの欄を 1 つにまとめる（同じものは 1 つ）
    List<String> merged(List<String> keys, String category) {
      final result = <String>[];
      for (final k in keys) {
        for (final v in _lists[k]!.values) {
          final key = skillKey(v, category: category);
          if (!result.any((e) => skillKey(e, category: category) == key)) result.add(v);
        }
      }
      return orNotUsed(result);
    }

    final start = normalizeYearMonth(_start.text);
    return {
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      if (_details.text.trim().isNotEmpty) 'details': _details.text.trim(),
      'skills': merged(_skillGroupKeys, 'skills'),
      'tools': merged(_toolGroupKeys, 'tools'),
      for (final k in _otherListKeys) k: list(k),
      if (start != null)
        'period': [start, _ongoing ? AppTexts.periodNow : normalizeYearMonth(_end.text)!],
      'link': _link.text.trim(),
      if (widget.isWork) 'workflow': Map<String, bool>.from(_workflow),
    };
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      );

  /// 「2024-04」などの文字 → その月の 1 日（読めなければ null）
  static DateTime? _toDate(String text) {
    final ym = normalizeYearMonth(text);
    if (ym == null) return null;
    final parts = ym.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// 開始・終了の欄：押すと年と月を選ぶ画面が開く（直接は打たない）。選んだら「2024年4月」と出す
  Widget _periodField({required bool isStart}) {
    final controller = isStart ? _start : _end;
    final enabled = isStart || !_ongoing;
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      decoration: _decoration(
        isStart ? DataTexts.formPeriodStart : DataTexts.formPeriodEnd,
        hint: DataTexts.pickerOpen,
      ).copyWith(
        prefixIcon: const Icon(Icons.calendar_month_outlined),
        suffixIcon: controller.text.isEmpty || !enabled
            ? null
            : IconButton(
                tooltip: DataTexts.pickerClear,
                icon: const Icon(Icons.clear),
                onPressed: () => setState(controller.clear),
              ),
      ),
      validator: isStart ? _validateStart : _validateEnd,
      onTap: () async {
        // 終了は開始より前を、開始は終了より後を選べない
        final picked = await showYearMonthPicker(
          context,
          title: isStart ? DataTexts.pickStart : DataTexts.pickEnd,
          initial: _toDate(controller.text) ?? (isStart ? null : _toDate(_start.text)),
          first: isStart ? null : _toDate(_start.text),
          last: isStart ? _toDate(_end.text) : null,
        );
        if (picked == null || !mounted) return;
        setState(() => controller.text = AppTexts.yearMonth(picked));
      },
    );
  }

  String _label(String key) => AppTexts.skillCategoryLabels[key] ?? key;

  /// 項目のボタン（フィルターのボタンと同じ見た目。入れた数をバッジで出す）
  Widget _techButton(String key) => ListenableBuilder(
        listenable: _lists[key]!,
        builder: (context, _) {
          final count = _lists[key]!.values.length;
          return Tooltip(
            message: DataTexts.tagPickerTooltip(_label(key)),
            child: OutlinedButton.icon(
              style: AppStyles.toolbarButton(context, active: count > 0),
              onPressed: () => _openPicker(key),
              icon: Badge.count(
                count: count,
                isLabelVisible: count > 0,
                child: const Icon(Icons.add_circle_outline, size: AppSizes.space20),
              ),
              // Skills・Tools のグループは「Skills：」「Tools：」を外した短い名前（上に見出しがあるため）
              label: Text(_label(key).split('：').last),
            ),
          );
        },
      );

  /// 入力欄と、すでにある項目の一覧を開く（スマホは下から出るシート）
  Future<void> _openPicker(String key) async {
    final controller = _lists[key]!;
    await showAppFilterModal<void>(
      context,
      builder: (ctx) => TagPickerPanel(
        title: _label(key),
        controller: controller,
        suggestions: widget.suggestions[key] ?? const [],
        onDone: () => Navigator.of(ctx).pop(),
      ),
    );
    controller.commitPending(); // 打ちかけの文字もタグにする
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSizes.space12);
    final labels = LanguageUtils.workflowLabels['ja']!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _title,
            autofocus: true,
            decoration: _decoration(DataTexts.formTitle),
            validator: (v) => (v ?? '').trim().isEmpty ? DataTexts.formTitleRequired : null,
          ),
          gap,
          TextFormField(controller: _description, decoration: _decoration(DataTexts.formDescription)),
          gap,
          TextFormField(
            controller: _details,
            minLines: 3,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            decoration: _decoration(DataTexts.formDetails),
          ),
          gap,

          // 期間（狭い画面では縦に並べる）
          Wrap(
            spacing: AppSizes.space12,
            runSpacing: AppSizes.space12,
            children: [
              SizedBox(
                width: AppSizes.projectFormPeriodWidth,
                child: _periodField(isStart: true),
              ),
              SizedBox(
                width: AppSizes.projectFormPeriodWidth,
                child: _periodField(isStart: false),
              ),
            ],
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _ongoing,
            onChanged: (v) => setState(() => _ongoing = v ?? false),
            title: Text(DataTexts.formOngoing, style: AppStyles.helpBody(context)),
          ),
          TextFormField(
            controller: _link,
            keyboardType: TextInputType.url,
            decoration: _decoration(DataTexts.formLink),
          ),
          const SizedBox(height: AppSizes.space16),

          // 技術：項目ごとの小さなボタン（押すと、入力欄とすでにある項目の一覧が開く）
          Text(DataTexts.formMainTech, style: AppStyles.filterGroupLabel(context)),
          const SizedBox(height: AppSizes.space4),
          Text(DataTexts.formTechNote, style: AppStyles.cardMeta(context)),
          const SizedBox(height: AppSizes.space8),
          // Skills・Tools はグループごと（Skills のグラフ・フィルター・詳細と同じ分け方）
          for (final (heading, keys) in [
            (AppTexts.fieldSkills, _skillGroupKeys),
            (AppTexts.fieldTools, _toolGroupKeys),
            (DataTexts.formOtherTech, _otherListKeys),
          ]) ...[
            Text(heading, style: AppStyles.cardMeta(context)),
            const SizedBox(height: AppSizes.space4),
            Wrap(
              spacing: AppSizes.space8,
              runSpacing: AppSizes.space8,
              children: [for (final k in keys) _techButton(k)],
            ),
            const SizedBox(height: AppSizes.space12),
          ],
          const SizedBox(height: AppSizes.space8),
          // 入れたものの一覧（項目：A, B）
          ListenableBuilder(
            listenable: Listenable.merge(_lists.values.toList()),
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final k in _allInputKeys)
                  if (_lists[k]!.values.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.space2),
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: '${_label(k)}：',
                            style: AppStyles.helpBody(context).copyWith(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: _lists[k]!.values.join(', ')),
                        ]),
                        style: AppStyles.helpBody(context),
                      ),
                    ),
              ],
            ),
          ),

          if (widget.isWork) ...[
            const SizedBox(height: AppSizes.space8),
            Text(DataTexts.formWorkflow, style: AppStyles.filterGroupLabel(context)),
            const SizedBox(height: AppSizes.space8),
            Wrap(
              spacing: AppSizes.space8,
              runSpacing: AppSizes.space8,
              children: [
                for (final e in labels.entries)
                  FilterChip(
                    label: Text(e.value),
                    selected: _workflow[e.key]!,
                    onSelected: (v) => setState(() => _workflow[e.key] = v),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
