import 'dart:typed_data';

Future<(String, Uint8List)?> pickFileBytes(
    {required String dialogTitle, required List<String> extensions}) async {
  throw UnsupportedError('file transfer not supported on this platform');
}

Future<void> saveBytesFile(Uint8List bytes,
    {required String fileName, required String dialogTitle}) async {
  throw UnsupportedError('file transfer not supported on this platform');
}

Future<void> saveTextFile(String text,
    {required String fileName, required String dialogTitle}) async {
  throw UnsupportedError('file transfer not supported on this platform');
}
