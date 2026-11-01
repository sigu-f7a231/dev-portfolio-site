// lib/widgets/settled_reveal.dart
//
// 「描画が落ち着くまで Progress indicator を出し、落ち着いたら中身を見せる」部品
// - 中身（child）は最初から裏で組み立て・描画しておく（透明・操作不可）。大きさも最初から確定するので、
//   表示の切り替えでダイアログなどの大きさが動かない
// - 中身が描かれてから AppSizes.settleFrames フレーム待ち、かつ最低表示時間（AppSizes.revealMinDuration）を
//   過ぎたら、フェードで表示する（重い描画でも描き切れるよう余裕を持たせている）
// - 待っている間は中央に M3 の円形 Progress indicator（AppLoadingIndicator）を出す
// 起動時のローディング（web/index.html ＋ lib/utils/app_ready.dart）と同じ考え方。
import 'package:flutter/material.dart';
import 'app_loading_indicator.dart';
import '../constants/app_sizes.dart';

class SettledReveal extends StatefulWidget {
  final Widget child;

  /// 最低限 Progress を見せる時間（短すぎてチラつかないように）
  final Duration minDuration;

  const SettledReveal({
    super.key,
    required this.child,
    this.minDuration = AppSizes.revealMinDuration,
  });

  @override
  State<SettledReveal> createState() => _SettledRevealState();
}

class _SettledRevealState extends State<SettledReveal> {
  bool _settled = false;

  @override
  void initState() {
    super.initState();
    _waitUntilSettled();
  }

  Future<void> _waitUntilSettled() async {
    final binding = WidgetsBinding.instance;
    Future<void> waitFrames() async {
      // 中身の最初の描画と、その後の描き直しが続く間（settleFrames フレーム分）待つ
      for (var i = 0; i < AppSizes.settleFrames; i++) {
        await binding.endOfFrame;
      }
    }

    // フレーム数と最低表示時間の「両方」を満たしたら表示する
    await Future.wait([waitFrames(), Future<void>.delayed(widget.minDuration)]);
    if (mounted) setState(() => _settled = true);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        // 中身：落ち着くまでは透明・操作不可（大きさは最初から確定）
        IgnorePointer(
          ignoring: !_settled,
          child: AnimatedOpacity(
            opacity: _settled ? 1 : 0,
            duration: reduceMotion ? Duration.zero : AppSizes.revealFadeDuration,
            curve: Curves.easeOut,
            child: widget.child,
          ),
        ),
        // 待っている間の Progress indicator
        if (!_settled) const AppLoadingIndicator(),
      ],
    );
  }
}
