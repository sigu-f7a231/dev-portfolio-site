// lib/widgets/year_month_picker.dart
//
// 年と月を選ぶ画面（Material 3 の日付選択と同じ見た目。日にちは選ばない）
// - 上に見出し（例：開始の年月を選ぶ）と、選んでいる年月を大きく
// - ‹ 2024年 › で年を移り、12 か月のボタンから月を選ぶ。年の部分を押すと年の一覧（12 年ずつ。‹ › で前後の 12 年）に切り替わる
// - [first] より前・[last] より後の月は選べない（例：終了は開始より前を選べない）
// - ［キャンセル］［OK］。OK で選んだ年月（その月の 1 日）を返す。キャンセルは null
import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';
import '../theme/app_theme.dart';

Future<DateTime?> showYearMonthPicker(
  BuildContext context, {
  required String title,
  DateTime? initial,
  DateTime? first,
  DateTime? last,
}) {
  final now = DateTime.now();
  final lo = first ?? DateTime(AppSizes.yearMonthPickerFirstYear);
  final hi = last ?? DateTime(now.year + AppSizes.yearMonthPickerYearsAhead, 12);
  var start = initial ?? DateTime(now.year, now.month);
  if (_ym(start) < _ym(lo)) start = DateTime(lo.year, lo.month);
  if (_ym(start) > _ym(hi)) start = DateTime(hi.year, hi.month);
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _YearMonthPicker(title: title, initial: start, first: lo, last: hi),
  );
}

/// 年月を比べるための数（年 × 12 ＋ 月）
int _ym(DateTime d) => d.year * 12 + d.month;

class _YearMonthPicker extends StatefulWidget {
  final String title;
  final DateTime initial;
  final DateTime first;
  final DateTime last;

  const _YearMonthPicker({
    required this.title,
    required this.initial,
    required this.first,
    required this.last,
  });

  @override
  State<_YearMonthPicker> createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<_YearMonthPicker> {
  late DateTime _selected = widget.initial;
  late int _year = widget.initial.year;
  bool _yearMode = false;

  /// 年の一覧に一度に出す年の数（3 列 × 4 行。スクロールしない）
  static const int _yearsPerPage = 12;

  /// 年の一覧の、今のページの最初の年
  late int _yearPageStart = _pageStartOf(widget.initial.year);

  int _pageStartOf(int year) => year - (year - widget.first.year) % _yearsPerPage;

  void _toggleYearMode() => setState(() {
        _yearMode = !_yearMode;
        if (_yearMode) _yearPageStart = _pageStartOf(_year); // 選んでいる年のページから
      });

  bool _enabled(int year, int month) {
    final v = year * 12 + month;
    return v >= _ym(widget.first) && v <= _ym(widget.last);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final now = DateTime.now();

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.space24, AppSizes.space16, AppSizes.space12, AppSizes.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: textTheme.labelLarge?.copyWith(color: colors.textSecondary)),
          const SizedBox(height: AppSizes.space12),
          Text(AppTexts.yearMonth(_selected), style: textTheme.headlineLarge),
        ],
      ),
    );

    // ‹ 2024年 ▾ ›
    final yearBar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.space12),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _toggleYearMode,
            icon: Icon(_yearMode ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            iconAlignment: IconAlignment.end,
            label: Text(DataTexts.pickerYear(_year)),
          ),
          const Spacer(),
          if (!_yearMode) ...[
            IconButton(
              tooltip: DataTexts.pickerPrevYear,
              icon: const Icon(Icons.chevron_left),
              onPressed: _year > widget.first.year ? () => setState(() => _year--) : null,
            ),
            IconButton(
              tooltip: DataTexts.pickerNextYear,
              icon: const Icon(Icons.chevron_right),
              onPressed: _year < widget.last.year ? () => setState(() => _year++) : null,
            ),
          ] else ...[
            // 年の一覧：前後の 12 年
            IconButton(
              tooltip: DataTexts.pickerPrevYears,
              icon: const Icon(Icons.chevron_left),
              onPressed: _yearPageStart > widget.first.year
                  ? () => setState(() => _yearPageStart -= _yearsPerPage)
                  : null,
            ),
            IconButton(
              tooltip: DataTexts.pickerNextYears,
              icon: const Icon(Icons.chevron_right),
              onPressed: _yearPageStart + _yearsPerPage <= widget.last.year
                  ? () => setState(() => _yearPageStart += _yearsPerPage)
                  : null,
            ),
          ],
        ],
      ),
    );

    Widget cell({
      required String label,
      required bool selected,
      required bool current,
      required bool enabled,
      required VoidCallback onTap,
    }) {
      final style = selected
          ? FilledButton.styleFrom(shape: const StadiumBorder())
          : (current
              ? OutlinedButton.styleFrom(shape: const StadiumBorder())
              : TextButton.styleFrom(shape: const StadiumBorder()));
      final child = Text(label);
      final onPressed = enabled ? onTap : null;
      return selected
          ? FilledButton(style: style, onPressed: onPressed, child: child)
          : current
              ? OutlinedButton(style: style, onPressed: onPressed, child: child)
              : TextButton(style: style, onPressed: onPressed, child: child);
    }

    final grid = _yearMode
        // 年の一覧（12 年ずつ。選ぶと月の一覧に戻る）
        ? SizedBox(
            height: AppSizes.yearMonthPickerGridHeight,
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: AppSizes.yearMonthPickerCellAspect,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space12),
              children: [
                for (var y = _yearPageStart;
                    y < _yearPageStart + _yearsPerPage && y <= widget.last.year;
                    y++)
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.space4),
                    child: cell(
                      label: DataTexts.pickerYear(y),
                      selected: y == _year,
                      current: y == now.year,
                      enabled: true,
                      onTap: () => setState(() {
                        _year = y;
                        _yearMode = false;
                      }),
                    ),
                  ),
              ],
            ),
          )
        // 12 か月
        : SizedBox(
            height: AppSizes.yearMonthPickerGridHeight,
            child: GridView.count(
              crossAxisCount: 3,
              childAspectRatio: AppSizes.yearMonthPickerCellAspect,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.space12),
              children: [
                for (var m = 1; m <= 12; m++)
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.space4),
                    child: cell(
                      label: DataTexts.pickerMonth(m),
                      selected: _selected.year == _year && _selected.month == m,
                      current: now.year == _year && now.month == m,
                      enabled: _enabled(_year, m),
                      onTap: () => setState(() => _selected = DateTime(_year, m)),
                    ),
                  ),
              ],
            ),
          );

    return Dialog(
      backgroundColor: colors.dialogBackground,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.yearMonthPickerWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const Divider(height: 1),
              const SizedBox(height: AppSizes.space8),
              yearBar,
              grid,
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSizes.space12, AppSizes.space8, AppSizes.space12, AppSizes.space12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppTexts.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      child: const Text(DataTexts.pickerOk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
