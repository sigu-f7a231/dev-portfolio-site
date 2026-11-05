// lib/utils/platform_keys.dart
//
// ショートカットキーの修飾キーを OS に合わせる
// - Mac（と iPad など Apple の端末）：⌘（Command）
// - Windows / Linux / Chromebook など：Ctrl
// Web でも defaultTargetPlatform はブラウザが動いている OS になる。
import 'package:flutter/foundation.dart';

bool get isApplePlatform =>
    defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.iOS;

/// ツールチップなどに出す修飾キーの名前（⌘ / Ctrl）
String get shortcutModifierLabel => isApplePlatform ? '⌘' : 'Ctrl';
