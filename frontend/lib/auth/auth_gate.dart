// lib/auth/auth_gate.dart
//
// ログインしているかを go_router に知らせる（ログインの状態が変わったら、URL の振り分け（redirect）をやり直させる）
// - ログインの状態そのものは AuthController（Riverpod）が持つ。これはその写し
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';

class AuthGate extends ChangeNotifier {
  AuthGate([this._loggedIn = false]);

  bool _loggedIn;
  bool get loggedIn => _loggedIn;
  set loggedIn(bool value) {
    if (value == _loggedIn) return;
    _loggedIn = value;
    notifyListeners();
  }
}

/// ログインの状態（authControllerProvider）に合わせて変わる AuthGate
final authGateProvider = Provider<AuthGate>((ref) {
  final gate = AuthGate(ref.read(authControllerProvider) != null);
  ref.listen(authControllerProvider.select((session) => session != null), (_, next) => gate.loggedIn = next);
  ref.onDispose(gate.dispose);
  return gate;
});
