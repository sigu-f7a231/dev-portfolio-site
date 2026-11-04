// 最小の幅より狭い画面での縮小表示のテスト
// 対象：lib/widgets/min_width_scaler.dart
//
// 実行：flutter test test/min_width_scaler_test.dart（dev_portfolio/ で）
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dev_portfolio/constants/app_sizes.dart';
import 'package:dev_portfolio/widgets/min_width_scaler.dart';

void _setScreen(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 幅 300 ちょうどの部品を横に並べた画面（320 未満では本来はみ出す）
Widget _app({required ValueChanged<Size> onSize}) => MaterialApp(
      builder: (context, child) => MinWidthScaler(child: child!),
      home: Builder(builder: (context) {
        onSize(MediaQuery.sizeOf(context));
        return const Scaffold(
          body: Row(
            mainAxisSize: MainAxisSize.min,
            children: [SizedBox(key: Key('wide'), width: 300, height: 40)],
          ),
        );
      }),
    );

void main() {
  testWidgets('最小の幅より狭い画面：最小の幅で組んで縮小し、はみ出さない', (tester) async {
    _setScreen(tester, const Size(240, 600));
    late Size seen;
    await tester.pumpWidget(_app(onSize: (s) => seen = s));

    // はみ出しエラー（RenderFlex overflowed）が出ていない
    expect(tester.takeException(), isNull);

    // 中の画面からは 320 幅に見える（高さは縮小の分だけ大きい）
    expect(seen.width, AppSizes.minSupportedWidth);
    expect(seen.height, closeTo(600 / (240 / AppSizes.minSupportedWidth), 0.001));

    // 画面上では 240/320 倍に縮小されている（幅 300 → 225）
    final rect = tester.getRect(find.byKey(const Key('wide')));
    expect(rect.width, closeTo(300 * 240 / AppSizes.minSupportedWidth, 0.001));
  });

  testWidgets('縮小中もタップできる', (tester) async {
    _setScreen(tester, const Size(240, 600));
    var tapped = 0;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MinWidthScaler(child: child!),
      home: Scaffold(
        body: Center(
          child: TextButton(onPressed: () => tapped++, child: const Text('tap')),
        ),
      ),
    ));
    await tester.tap(find.text('tap'));
    expect(tapped, 1);
  });

  testWidgets('最小の幅以上では何もしない', (tester) async {
    for (final width in [AppSizes.minSupportedWidth, 390.0, 1200.0]) {
      _setScreen(tester, Size(width, 800));
      late Size seen;
      await tester.pumpWidget(_app(onSize: (s) => seen = s));
      expect(seen, Size(width, 800));
      expect(tester.getRect(find.byKey(const Key('wide'))).width, 300);
    }
  });
}
