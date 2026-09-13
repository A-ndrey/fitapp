import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

abstract interface class LibraryTransferFileGateway {
  Future<String?> pickJson();

  Future<void> saveJson({required String fileName, required String contents});
}

class DeviceLibraryTransferFileGateway implements LibraryTransferFileGateway {
  const DeviceLibraryTransferFileGateway();

  @override
  Future<String?> pickJson() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Choose a FitApp library file',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
    if (file == null) {
      return null;
    }
    final bytes = await file.readAsBytes();
    return utf8.decode(bytes);
  }

  @override
  Future<void> saveJson({
    required String fileName,
    required String contents,
  }) async {
    await FilePicker.saveFile(
      dialogTitle: 'Save FitApp library file',
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );
  }
}
