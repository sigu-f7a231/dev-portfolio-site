// lib/widgets/app_loading_indicator.dart
//
// 読み込み中の表示＝ Material 3 の Progress indicator（円形・不確定）
// https://m3.material.io/components/progress-indicators/overview
//
// Flutter 公式の CircularProgressIndicator を、M3 の最新仕様（year2023: false）で使う。
// - 弧（primary）とトラック（secondaryContainer）の間に隙間があり、線の端は丸い
// - 色・太さ・隙間は M3 の既定値（テーマの progressIndicatorTheme でも year2023: false を設定済み）
// 起動時の HTML 版（web/index.html）も同じ見た目で描いている。
import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';
import '../constants/app_texts.dart';

class AppLoadingIndicator extends StatelessWidget {
  /// 表示する大きさ（円の直径）
  final double size;

  const AppLoadingIndicator({
    super.key,
    this.size = AppSizes.loadingIndicatorSize,
  });

  @override
  Widget build(BuildContext context) {
    // 小さく使うとき（ボタンの中など）は線を細くする
    final small = size < AppSizes.loadingIndicatorSize;

    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        year2023: false,
        strokeWidth: small ? AppSizes.loadingIndicatorStrokeSmall : null,
        semanticsLabel: AppTexts.loading,
      ),
    );
  }
}
