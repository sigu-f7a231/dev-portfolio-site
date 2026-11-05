// lib/utils/file_saver_web.dart
//
// ファイルを「名前を付けて保存」する Web 用の実装（dart:js_interop / package:web を使う）
// file_saver.dart から自動で選ばれる
// - Chrome / Edge：File System Access API（showSaveFilePicker）で OS の保存ダイアログを開く
// - それ以外（Firefox / Safari など）：保存ダイアログが使えないので、通常のダウンロードにする
//   （ブラウザ側で「保存先を毎回確認する」設定なら、そこで保存先を選べる）
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:web/web.dart' as web; // 通常ダウンロード（フォールバック）用。dart:html の後継
import '../constants/app_sizes.dart';
import 'file_saver_types.dart';


class FileSaver {
  FileSaver._();

  /// [text] を [fileName] として保存する。[mimeType] と [extensions] は保存ダイアログのファイル種類
  static Future<FileSaveResult> saveTextAs({
    required String fileName,
    required String text,
    required String description,
    required String mimeType,
    required List<String> extensions,
  }) =>
      _saveAs(
        fileName: fileName,
        data: text.toJS,
        description: description,
        mimeType: mimeType,
        blobType: '$mimeType;charset=utf-8',
        extensions: extensions,
      );

  /// [bytes]（Excel など文字ではないファイル）を [fileName] として保存する
  static Future<FileSaveResult> saveBytesAs({
    required String fileName,
    required Uint8List bytes,
    required String description,
    required String mimeType,
    required List<String> extensions,
  }) =>
      _saveAs(
        fileName: fileName,
        data: bytes.toJS,
        description: description,
        mimeType: mimeType,
        blobType: mimeType,
        extensions: extensions,
      );

  static Future<FileSaveResult> _saveAs({
    required String fileName,
    required JSAny data,
    required String description,
    required String mimeType,
    required String blobType,
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
        await writable.callMethod<JSPromise<JSAny?>>('write'.toJS, data).toDart;
        await writable.callMethod<JSPromise<JSAny?>>('close'.toJS).toDart;
        return FileSaveResult.saved;
      } catch (e) {
        // 保存ダイアログで「キャンセル」した場合は AbortError になる
        if (e.toString().contains('AbortError')) return FileSaveResult.cancelled;
        rethrow;
      }
    }

    // フォールバック：通常のダウンロード
    final blob = web.Blob(
      <JSAny>[data].toJS,
      web.BlobPropertyBag(type: blobType),
    );
    final url = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..click();
    // ダウンロード開始を待ってから URL を解放する
    Future.delayed(AppSizes.downloadUrlRevokeDelay, () => web.URL.revokeObjectURL(url));
    return FileSaveResult.downloaded;
  }
}
