// lib/utils/file_saver.dart
//
// テキストファイルを「名前を付けて保存」する（Web 専用）
// - Chrome / Edge：File System Access API（showSaveFilePicker）で OS の保存ダイアログを開く
// - それ以外（Firefox / Safari など）：保存ダイアログが使えないので、通常のダウンロードにする
//   （ブラウザ側で「保存先を毎回確認する」設定なら、そこで保存先を選べる）
import 'dart:html' as html; // 通常ダウンロード（フォールバック）用
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import '../constants/app_sizes.dart';

enum FileSaveResult {
  /// 保存ダイアログで保存した
  saved,

  /// 保存ダイアログでキャンセルした
  cancelled,

  /// 保存ダイアログが使えないブラウザなので、通常のダウンロードにした
  downloaded,
}

class FileSaver {
  FileSaver._();

  /// [text] を [fileName] として保存する。[mimeType] と [extensions] は保存ダイアログのファイル種類
  static Future<FileSaveResult> saveTextAs({
    required String fileName,
    required String text,
    required String description,
    required String mimeType,
    required List<String> extensions,
  }) async {
    if (globalContext.has('showSaveFilePicker')) {
      final options = {
        'suggestedName': fileName,
        'types': [
          {
            'description': description,
            'accept': {mimeType: extensions},
          },
        ],
      }.jsify();

      try {
        final handle = await globalContext
            .callMethod<JSPromise<JSObject>>('showSaveFilePicker'.toJS, options)
            .toDart;
        final writable =
            await handle.callMethod<JSPromise<JSObject>>('createWritable'.toJS).toDart;
        await writable.callMethod<JSPromise<JSAny?>>('write'.toJS, text.toJS).toDart;
        await writable.callMethod<JSPromise<JSAny?>>('close'.toJS).toDart;
        return FileSaveResult.saved;
      } catch (e) {
        // 保存ダイアログで「キャンセル」した場合は AbortError になる
        if (e.toString().contains('AbortError')) return FileSaveResult.cancelled;
        rethrow;
      }
    }

    // フォールバック：通常のダウンロード
    final blob = html.Blob([text], '$mimeType;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = fileName
      ..click();
    // ダウンロード開始を待ってから URL を解放する
    Future.delayed(AppSizes.downloadUrlRevokeDelay, () => html.Url.revokeObjectUrl(url));
    return FileSaveResult.downloaded;
  }
}
