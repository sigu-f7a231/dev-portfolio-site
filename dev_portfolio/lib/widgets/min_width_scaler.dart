// lib/widgets/min_width_scaler.dart
//
// 対応する最小の幅（AppSizes.minSupportedWidth）より狭い画面で、
// その幅のレイアウトのまま画面幅に合わせて縮小して表示する。
// - 部品が入りきらずに「はみ出しエラー（黄色と黒の縞）」になるのを防ぐ
// - 最小の幅以上では何もしない（そのまま表示）
// - 子には MediaQuery の size も縮小前の大きさで渡すので、各画面の幅の判定と食い違わない
// MaterialApp の builder で使い、ダイアログやポップアップも含めて全体に効かせる。
import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

class MinWidthScaler extends StatelessWidget {
  final Widget child;
  final double minWidth;

  const MinWidthScaler({
    super.key,
    required this.child,
    this.minWidth = AppSizes.minSupportedWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (!width.isFinite || width >= minWidth || width <= 0) return child;

        // 例：幅 250 の画面 → 320 で組んで 250/320 倍に縮小
        final scale = width / minWidth;
        final height = constraints.maxHeight / scale;
        final mq = MediaQuery.of(context);

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: minWidth,
            maxWidth: minWidth,
            minHeight: height,
            maxHeight: height,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: MediaQuery(
                data: mq.copyWith(size: Size(minWidth, height)),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
