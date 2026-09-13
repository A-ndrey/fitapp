import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../models/library_transfer.dart';
import 'library_transfer_file_gateway.dart';
import 'library_transfer_service.dart';

class LibraryTransferController extends ChangeNotifier {
  LibraryTransferController({
    required LibraryTransferService service,
    LibraryTransferFileGateway files = const DeviceLibraryTransferFileGateway(),
  }) : _service = service,
       _files = files;

  final LibraryTransferService _service;
  final LibraryTransferFileGateway _files;

  bool _isBusy = false;
  String? _error;

  bool get isBusy => _isBusy;

  String? get error => _error;

  String exportCategory(LibraryCategory category) =>
      _service.exportCategory(category);

  String exportItem(LibraryCategory category, String id) =>
      _service.exportItem(category, id);

  LibraryImportPreview preview(String source) => _service.preview(source);

  LibraryImportResult apply(
    LibraryImportPreview preview, {
    required Set<String> selectedKeys,
    Set<String> copyKeys = const {},
  }) {
    return _service.apply(
      preview,
      selectedKeys: selectedKeys,
      copyKeys: copyKeys,
    );
  }

  Future<void> copyJson(String source) async {
    await _run(() => Clipboard.setData(ClipboardData(text: source)));
  }

  Future<String?> readClipboard() async {
    return _run(() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text == null || text.isEmpty) {
        throw const FormatException('The clipboard does not contain JSON.');
      }
      return text;
    });
  }

  Future<String?> pickJson() => _runNullable(_files.pickJson);

  Future<void> saveJson({
    required String fileName,
    required String contents,
  }) async {
    await _run(() => _files.saveJson(fileName: fileName, contents: contents));
  }

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      return await action();
    } on Object catch (error) {
      _error = _messageFor(error);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<T?> _runNullable<T>(Future<T?> Function() action) async {
    _isBusy = true;
    _error = null;
    notifyListeners();
    try {
      return await action();
    } on Object catch (error) {
      _error = _messageFor(error);
      return null;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _messageFor(Object error) {
    if (error is FormatException) {
      return error.message.toString();
    }
    return error.toString();
  }
}
