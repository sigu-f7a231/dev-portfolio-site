// lib/sections/header/project_data_dialog.dart
//
// ヘッダーの［データ］：Work / Private のプロジェクトの追加・更新（1 つの画面の中で順に選ぶ。［戻る］で前に戻れる）
//
//   何をしますか？ ── 更新 ── どちら？（Work / Private）→ これまでのアップロード画面（丸ごと置き換え）
//                 └─ 追加 ── どちら？（Work / Private）
//                            ├─ ファイル・貼り付けで追加 → これまでのアップロード画面（今の一覧の後ろに足す）
//                            └─ 画面上で入力 ─┬─ 1 件 ─┬─ 入力フォーム
//                                             │        └─ テキスト（YAML / Markdown・ファイル）
//                                             └─ 複数件 → テキスト（YAML / Markdown・ファイル）
//                                                        → 全部追加する / 選んだものだけ追加する
//   どの道を通っても、反映の前に確認画面を出す（追加は project_add_confirm.dart、更新はアップロード画面の確認）
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../constants/app_sizes.dart';
import '../../constants/app_texts.dart';
import '../../theme/app_styles.dart';
import '../../theme/app_theme.dart';
import '../../utils/asset_text.dart';
import '../../utils/data_format.dart';
import '../../utils/project_append.dart';
import '../../utils/private_yaml_loader.dart';
import '../../utils/work_yaml_loader.dart';
import '../../widgets/app_segment.dart';
import '../../widgets/upload_parts.dart';
import 'project_add_confirm.dart';
import 'project_form.dart';
import 'yaml_format_help.dart';
import 'yaml_upload_dialog.dart';

/// ［データ］の画面を開く。反映したら [onSaved]（Skills / Projects の作り直し）を呼ぶ
Future<void> showProjectDataDialog(BuildContext context, {VoidCallback? onSaved}) =>
    _show(context, onSaved: onSaved);

/// [resume] があれば、その途中の画面から開く（アップロード画面の［戻る］で戻ってきたとき）
Future<void> _show(BuildContext context, {VoidCallback? onSaved, _Resume? resume}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ProjectDataDialog(hostContext: context, onSaved: onSaved, resume: resume),
  );
}

enum _Step { action, target, method, count, singleInput, form, text, pick }

enum _Action { add, update }

/// 途中から開き直すときの状態（今いる画面・それまでに通った画面と選んだもの）
class _Resume {
  final _Step step;
  final List<_Step> history;
  final List<String> crumbs;
  final _Action? action;
  final String dataType;

  const _Resume(this.step, this.history, this.crumbs, this.action, this.dataType);
}

class _ProjectDataDialog extends StatefulWidget {
  /// 画面を開いた元（この画面を閉じてからアップロード画面を開くときに使う）
  final BuildContext hostContext;
  final VoidCallback? onSaved;
  final _Resume? resume;

  const _ProjectDataDialog({required this.hostContext, required this.onSaved, this.resume});

  @override
  State<_ProjectDataDialog> createState() => _ProjectDataDialogState();
}

class _ProjectDataDialogState extends State<_ProjectDataDialog> {
  late _Step _step = widget.resume?.step ?? _Step.action;
  late final _history = <_Step>[...?widget.resume?.history];
  // 選んできたもの（見出しの上に「追加 › Work › …」と出す）
  late final _crumbs = <String>[...?widget.resume?.crumbs];

  late _Action? _action = widget.resume?.action;
  late String _dataType = widget.resume?.dataType ?? 'work';
  bool _single = true;

  // テキストから追加
  final _text = TextEditingController();
  String? _fileName; // ファイルから読んだとき（中身を書き換えたら外す）
  String? _fileText;
  List<String> _errors = const [];

  /// 保存・コピー・入力欄に入れるテンプレートの形式（YAML / Markdown）
  DataFormat _templateFormat = DataFormat.yaml;

  // 複数件：見つかったもの・全部か選んだものだけか
  List<Map<String, dynamic>> _found = const [];
  bool _pickAll = true;
  Set<int> _selected = {};

  final _form = GlobalKey<ProjectFormState>();

  /// 入力フォームの技術の候補（今の Work / Private に書かれているもの）
  Map<String, List<String>> _suggestions = const {};

  /// 入力フォームを開く前に、候補を読む（読めなくてもフォームは開く）
  Future<void> _openForm() async {
    try {
      final texts =
          await Future.wait([WorkYamlLoader.loadYamlString(), PrivateYamlLoader.loadYamlString()]);
      _suggestions = tagSuggestions(texts);
    } catch (_) {
      _suggestions = const {};
    }
    if (mounted) _goTo(_Step.form, DataTexts.form);
  }
  bool _busy = false;

  bool get _isWork => _dataType == 'work';
  String get _label => _isWork ? AppTexts.work : AppTexts.private;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _goTo(_Step step, String crumb) => setState(() {
        _history.add(_step);
        _crumbs.add(crumb);
        _step = step;
        _errors = const [];
      });

  void _back() => setState(() {
        _step = _history.removeLast();
        _crumbs.removeLast();
        _errors = const [];
      });

  /// この画面を閉じて、これまでのアップロード画面を開く（[append] なら今の一覧に足す）
  /// アップロード画面の［戻る］で、この画面の今の選択（更新なら Work / Private、追加なら追加の方法）に戻る
  void _openUpload({required bool append}) {
    final resume = _Resume(_step, List.of(_history), List.of(_crumbs), _action, _dataType);
    Navigator.of(context).pop();
    final host = widget.hostContext;
    if (!host.mounted) return;
    showYamlUploadDialog(
      host,
      dataType: _dataType,
      onSaved: widget.onSaved,
      append: append,
      onBack: () {
        if (host.mounted) _show(host, onSaved: widget.onSaved, resume: resume);
      },
    );
  }

  // ---------- 選んだとき ----------
  void _chooseAction(_Action a) {
    _action = a;
    _goTo(_Step.target, a == _Action.add ? DataTexts.add : DataTexts.update);
  }

  void _chooseTarget(String dataType) {
    _dataType = dataType;
    if (_action == _Action.update) {
      _openUpload(append: false); // 更新＝これまでのアップロード画面（丸ごと置き換え）
      return;
    }
    _goTo(_Step.method, _label);
  }

  void _chooseCount(bool single) {
    _single = single;
    _goTo(single ? _Step.singleInput : _Step.text, single ? DataTexts.single : DataTexts.multiple);
  }

  // ---------- 次へ ----------
  Future<void> _confirm(List<Map<String, dynamic>> adding) async {
    setState(() => _busy = true);
    try {
      await confirmAndAppendProjects(
        context,
        dataType: _dataType,
        adding: adding,
        onSaved: widget.onSaved,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _nextFromForm() async {
    final project = _form.currentState?.collect();
    if (project == null) return; // 入力の誤りはフォームに出る
    await _confirm([project]);
  }

  Future<void> _nextFromText() async {
    final raw = _text.text;
    final input = readProjectsInput(
      raw,
      dataType: _dataType,
      fileName: raw == _fileText ? _fileName : null,
    );
    if (!input.isOk) {
      setState(() => _errors = input.errors.isEmpty ? const [DataTexts.noProjectsFound] : input.errors);
      return;
    }
    if (_single) {
      if (input.projects.length != 1) {
        setState(() => _errors = [DataTexts.notSingle(input.projects.length)]);
        return;
      }
      await _confirm(input.projects);
      return;
    }
    setState(() {
      _found = input.projects;
      _pickAll = true;
      _selected = {for (var i = 0; i < _found.length; i++) i};
    });
    _goTo(_Step.pick, DataTexts.found(input.projects.length));
  }

  Future<void> _nextFromPick() async {
    final adding = _pickAll
        ? _found
        : [for (var i = 0; i < _found.length; i++) if (_selected.contains(i)) _found[i]];
    if (adding.isEmpty) {
      setState(() => _errors = const [DataTexts.selectAtLeastOne]);
      return;
    }
    await _confirm(adding);
  }

  Future<void> _pickFile() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: acceptedExtensions,
        withData: true,
      );
      final file = picked?.files.single;
      if (file == null || file.bytes == null) return;
      final text = utf8.decode(file.bytes!);
      setState(() {
        _text.text = text;
        _fileName = file.name;
        _fileText = text;
        _errors = const [];
      });
    } catch (e) {
      setState(() => _errors = [AppTexts.fileReadFailed(e)]);
    }
  }

  /// テキストを貼り付ける画面（アップロード画面と同じ。クリップボードからの貼り付け・クリア付き）
  Future<void> _paste() async {
    final text = await showPasteYamlDialog(context, initialText: _text.text);
    if (text == null || !mounted) return; // キャンセル
    setState(() {
      _text.text = text;
      _errors = const [];
    });
  }

  /// サンプルを入力欄に入れる（書き換えて使う）。1 件ならテンプレート、複数件なら 2 件以上入ったサンプル
  Future<void> _insertSample() async {
    final kind = projectKind(_dataType);
    try {
      final text = await loadAssetText(_single
          ? templateAssetPath(kind, _templateFormat)
          : multiSampleAssetPath(kind, _templateFormat));
      if (!mounted) return;
      setState(() {
        _text.text = text;
        _fileName = _single
            ? templateFileName(kind, _templateFormat)
            : multiSampleAssetPath(kind, _templateFormat).split('/').last;
        _fileText = text;
        _errors = const [];
      });
    } catch (e) {
      setState(() => _errors = [AppTexts.fileReadFailed(e)]);
    }
  }

  // ---------- 画面 ----------
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final wide = _step == _Step.form || _step == _Step.text || _step == _Step.pick;

    final (heading, body) = switch (_step) {
      _Step.action => (DataTexts.stepAction, _actionStep()),
      _Step.target => (DataTexts.stepTarget, _targetStep()),
      _Step.method => (DataTexts.stepMethod, _methodStep()),
      _Step.count => (DataTexts.stepCount, _countStep()),
      _Step.singleInput => (DataTexts.stepSingleInput, _singleInputStep()),
      _Step.form => (
          DataTexts.stepForm,
          ProjectForm(key: _form, isWork: _isWork, suggestions: _suggestions),
        ),
      _Step.text => (DataTexts.stepText, _textStep()),
      _Step.pick => (DataTexts.stepPick, _pickStep()),
    };
    final VoidCallback? next = switch (_step) {
      _Step.form => _nextFromForm,
      _Step.text => _nextFromText,
      _Step.pick => _nextFromPick,
      _ => null,
    };

    return AlertDialog(
      backgroundColor: colors.dialogBackground,
      icon: Icon(Icons.dataset_outlined, color: colors.primary),
      title: Text(DataTexts.title, textAlign: TextAlign.center, style: AppStyles.dialogTitle(context)),
      content: SizedBox(
        width: wide ? AppSizes.helpDialogWidth : AppSizes.uploadDialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_crumbs.isNotEmpty) ...[
                Text(_crumbs.join(' › '), style: AppStyles.cardMeta(context)),
                const SizedBox(height: AppSizes.space4),
              ],
              Row(
                children: [
                  Expanded(child: Text(heading, style: AppStyles.helpHeading(context))),
                  // 入力する画面では、アップロード画面と同じ書き方の説明（ⓘ）を開ける
                  if (_step == _Step.text || _step == _Step.form)
                    IconButton(
                      icon: Icon(Icons.info_outline, color: colors.textSecondary),
                      tooltip: AppTexts.formatHelpTooltip,
                      onPressed: () => showYamlFormatHelp(context, _dataType),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.space12),
              body,
              for (final e in _errors)
                Padding(
                  padding: const EdgeInsets.only(top: AppSizes.space8),
                  child: Text('${AppTexts.bullet}$e', style: AppStyles.dialogError(context)),
                ),
            ],
          ),
        ),
      ),
      actionsOverflowButtonSpacing: AppSizes.space8,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppTexts.cancel),
        ),
        if (_history.isNotEmpty)
          OutlinedButton(onPressed: _busy ? null : _back, child: const Text(DataTexts.back)),
        if (next != null)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _text,
            builder: (context, value, _) => FilledButton(
              // テキストは空のときは押せない
              onPressed: _busy || (_step == _Step.text && value.text.trim().isEmpty) ? null : next,
              child: const Text(DataTexts.next),
            ),
          ),
      ],
    );
  }

  Widget _choice(IconData icon, String title, String note, VoidCallback onTap) => Card.outlined(
        margin: const EdgeInsets.only(bottom: AppSizes.space8),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(note),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );

  Widget _choices(List<Widget> children) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);

  Widget _actionStep() => _choices([
        _choice(Icons.playlist_add, DataTexts.add, DataTexts.addNote, () => _chooseAction(_Action.add)),
        _choice(Icons.sync, DataTexts.update, DataTexts.updateNote,
            () => _chooseAction(_Action.update)),
      ]);

  Widget _targetStep() => _choices([
        _choice(Icons.work_outline, AppTexts.work, DataTexts.workNote, () => _chooseTarget('work')),
        _choice(Icons.lock_outline, AppTexts.private, DataTexts.privateNote,
            () => _chooseTarget('private')),
      ]);

  Widget _methodStep() => _choices([
        _choice(Icons.edit_note, DataTexts.onScreen, DataTexts.onScreenNote,
            () => _goTo(_Step.count, DataTexts.onScreen)),
        _choice(Icons.upload_file, DataTexts.existing, DataTexts.existingNote,
            () => _openUpload(append: true)),
      ]);

  Widget _countStep() => _choices([
        _choice(Icons.looks_one_outlined, DataTexts.single, DataTexts.singleNote,
            () => _chooseCount(true)),
        _choice(Icons.library_add_outlined, DataTexts.multiple, DataTexts.multipleNote,
            () => _chooseCount(false)),
      ]);

  Widget _singleInputStep() => _choices([
        _choice(Icons.dynamic_form_outlined, DataTexts.form, DataTexts.formNote,
            _openForm),
        _choice(Icons.notes, DataTexts.text, DataTexts.textNote,
            () => _goTo(_Step.text, DataTexts.text)),
      ]);

  Widget _textStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DataTexts.textLead(_single), style: AppStyles.helpBody(context)),
          const SizedBox(height: AppSizes.space12),
          // アップロード画面と同じ：テンプレート［形式］［保存］［コピー］／ データ［ファイルを選択］［テキストを貼り付け］
          UploadSourcePanel(
            templateFormat: _templateFormat,
            onTemplateFormatChanged: (f) => setState(() => _templateFormat = f),
            onSaveTemplate: () =>
                saveTemplateFile(context, kind: projectKind(_dataType), format: _templateFormat),
            onCopyTemplate: () => copyTemplateText(
              context,
              assetPath: templateAssetPath(projectKind(_dataType), _templateFormat),
              fileName: templateFileName(projectKind(_dataType), _templateFormat),
            ),
            onPickFile: _pickFile,
            onPasteText: _paste,
            hasSource: _text.text.isNotEmpty,
          ),
          const SizedBox(height: AppSizes.space8),
          // サンプルを入力欄に入れて、そのまま書き換えられる
          TextButton.icon(
            onPressed: _insertSample,
            icon: const Icon(Icons.post_add),
            label: const Text(DataTexts.insertSample),
          ),
          const SizedBox(height: AppSizes.space8),
          TextField(
            controller: _text,
            minLines: AppSizes.pasteMinLines,
            maxLines: AppSizes.pasteMaxLines,
            keyboardType: TextInputType.multiline,
            // YAML はインデントが大事なので、自動の書き換えをしない
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            style: AppStyles.codeText(context),
            onChanged: (_) {
              if (_errors.isNotEmpty) setState(() => _errors = const []);
            },
            decoration: const InputDecoration(
              hintText: DataTexts.textHint,
              hintMaxLines: AppSizes.pasteMinLines,
              border: OutlineInputBorder(),
            ),
          ),
          if (_fileName != null && _text.text == _fileText) ...[
            const SizedBox(height: AppSizes.space8),
            SelectedFileStatus(fileName: _fileName),
          ],
        ],
      );

  Widget _pickStep() {
    String period(Object? p) => p is List ? p.join(' 〜 ') : (p?.toString() ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AppSegment<bool>(
            value: _pickAll,
            onChanged: (v) => setState(() {
              _pickAll = v;
              _errors = const [];
            }),
            items: const [
              AppSegmentItem(value: true, label: DataTexts.addAll),
              AppSegmentItem(value: false, label: DataTexts.addSelected),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.space12),
        if (!_pickAll) ...[
          Wrap(
            spacing: AppSizes.space8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(DataTexts.selectedCount(_selected.length, _found.length),
                  style: AppStyles.cardMeta(context)),
              TextButton(
                onPressed: () => setState(
                    () => _selected = {for (var i = 0; i < _found.length; i++) i}),
                child: const Text(DataTexts.selectAll),
              ),
              TextButton(
                onPressed: () => setState(() => _selected = {}),
                child: const Text(DataTexts.selectNone),
              ),
            ],
          ),
        ],
        for (var i = 0; i < _found.length; i++)
          _pickAll
              ? ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(Icons.check),
                  title: Text('${_found[i]['title']}'),
                  subtitle: period(_found[i]['period']).isEmpty
                      ? null
                      : Text(period(_found[i]['period'])),
                )
              : CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: _selected.contains(i),
                  onChanged: (v) => setState(() {
                    v == true ? _selected.add(i) : _selected.remove(i);
                    _errors = const [];
                  }),
                  title: Text('${_found[i]['title']}'),
                  subtitle: period(_found[i]['period']).isEmpty
                      ? null
                      : Text(period(_found[i]['period'])),
                ),
      ],
    );
  }
}
