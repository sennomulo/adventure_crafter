import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:get/get.dart';

Future<(String, Uint8List)?> pickFileBytes(
    {required String dialogTitle, required List<String> extensions}) async {
  final result = await FilePicker.pickFiles(
    dialogTitle: dialogTitle,
    type: GetPlatform.isAndroid ? FileType.any : FileType.custom,
    allowedExtensions: GetPlatform.isAndroid ? null : extensions,
    withData: true,
  );
  if (result == null || result.count != 1) return null;
  final f = result.files.single;
  if (f.bytes == null) return null;
  return (f.name, f.bytes!);
}

Future<void> saveBytesFile(Uint8List bytes,
    {required String fileName, required String dialogTitle}) async {
  if (GetPlatform.isDesktop) {
    final path = await FilePicker.saveFile(
        dialogTitle: dialogTitle, fileName: fileName);
    if (path != null) {
      await File(path).writeAsBytes(bytes, flush: true);
    }
  } else {
    await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(data: bytes, fileName: fileName),
    );
  }
}

Future<void> saveTextFile(String text,
    {required String fileName, required String dialogTitle}) async {
  if (GetPlatform.isDesktop) {
    final path = await FilePicker.saveFile(
        dialogTitle: dialogTitle, fileName: fileName);
    if (path != null) {
      await File(path).writeAsString(text, flush: true);
    }
  } else {
    await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
          data: utf8.encode(text), fileName: fileName),
    );
  }
}
