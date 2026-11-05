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

  /// 「名前を付けて保存」のダイアログを先に開き、保存先が決まってから [make] で中身を作って書き込む
  /// （PDF など作るのに時間がかかるものは、作ったあとだとブラウザが保存ダイアログを開かせないため。
  ///  showSaveFilePicker はボタンを押した直後にしか呼べない）
  /// - キャンセル → cancelled（[make] は呼ばない）
  /// - 保存ダイアログが使えないブラウザ（Firefox / Safari など）→ 作ってから通常のダウンロード（downloaded）
  static Future<FileSaveResult> saveGeneratedBytesAs({
    required String fileName,
    required String description,
    required String mimeType,
    required List<String> extensions,
    required Future<Uint8List> Function() make,
  }) async {
    if (globalContext.has('showSaveFilePicker')) {
      JSObject? handle;
      try {
        handle = await _pick(fileName, description, mimeType, extensions);
      } catch (e) {
        if (e.toString().contains('AbortError')) return FileSaveResult.cancelled;
        // 開けなかったとき（SecurityError など）は、下の通常のダウンロードにする
      }
      if (handle != null) {
        final bytes = await make();
        await _write(handle, bytes.toJS);
        return FileSaveResult.saved;
      }
    }
    final bytes = await make();
    _download(fileName, bytes.toJS, mimeType);
    return FileSaveResult.downloaded;
  }

  static Future<JSObject> _pick(
      String fileName, String description, String mimeType, List<String> extensions) {
    final options = {
      'suggestedName': fileName,
      'types': [
        {
          'description': description,
          'accept': {mimeType: extensions},
        },
      ],
    }.jsify();
    return globalContext
        .callMethod<JSPromise<JSObject>>('showSaveFilePicker'.toJS, options)
        .toDart;
  }

  static Future<void> _write(JSObject handle, JSAny data) async {
    final writable = await handle.callMethod<JSPromise<JSObject>>('createWritable'.toJS).toDart;
    await writable.callMethod<JSPromise<JSAny?>>('write'.toJS, data).toDart;
    await writable.callMethod<JSPromise<JSAny?>>('close'.toJS).toDart;
  }

  static void _download(String fileName, JSAny data, String blobType) {
    final blob = web.Blob(<JSAny>[data].toJS, web.BlobPropertyBag(type: blobType));
    final url = web.URL.createObjectURL(blob);
    web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..click();
    // ダウンロード開始を待ってから URL を解放する
    Future.delayed(AppSizes.downloadUrlRevokeDelay, () => web.URL.revokeObjectURL(url));
  }

  static Future<FileSaveResult> _saveAs({
    required String fileName,
    required JSAny data,
    required String description,
    required String mimeType,
    required String blobType,
    required List<String> extensions,
  }) async {
    if (globalContext.has('showSaveFilePicker')) {
      try {
        final handle = await _pick(fileName, description, mimeType, extensions);
        await _write(handle, data);
        return FileSaveResult.saved;
      } catch (e) {
        // 保存ダイアログで「キャンセル」した場合は AbortError になる
        if (e.toString().contains('AbortError')) return FileSaveResult.cancelled;
        // 開けなかったとき（SecurityError / NotAllowedError）は、下の通常のダウンロードにする
      }
    }

    // フォールバック：通常のダウンロード
    _download(fileName, data, blobType);
    return FileSaveResult.downloaded;
  }
}
