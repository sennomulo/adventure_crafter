import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

Future<(String, Uint8List)?> pickFileBytes(
    {required String dialogTitle, required List<String> extensions}) {
  final loadEnded = Completer<(String, Uint8List)?>();

  final uploadInput = HTMLInputElement()..type = 'file';
  uploadInput.draggable = true;
  uploadInput.accept = extensions.map((e) => '.$e').join(',');
  _addToDom(uploadInput);
  uploadInput.showPicker();

  uploadInput.onChange.listen((e) {
    final file = uploadInput.files?.item(0);
    if (file == null) {
      loadEnded.complete(null);
    } else {
      file.arrayBuffer().toDart.then((buffer) {
        loadEnded.complete((file.name, buffer.toDart.asUint8List()));
      });
    }
  });

  return loadEnded.future;
}

Future<void> saveBytesFile(Uint8List bytes,
    {required String fileName, required String dialogTitle}) async {
  final blob = Blob(<JSUint8Array>[bytes.toJS].toJS,
      BlobPropertyBag(type: 'application/octet-stream'));
  _saveBlobFile(blob, fileName: fileName);
}

Future<void> saveTextFile(String text,
    {required String fileName, required String dialogTitle}) async {
  final blob = Blob(<JSUint8Array>[utf8.encode(text).toJS].toJS,
      BlobPropertyBag(type: 'application/json'));
  _saveBlobFile(blob, fileName: fileName);
}

void _saveBlobFile(Blob blob, {required String fileName}) {
  final url = URL.createObjectURL(blob);

  final element = HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  _addToDom(element);
  element.click();
}

void _addToDom(Element element) {
  const containerId = '__file-container';

  Element? target = document.getElementById(containerId);
  if (target == null) {
    target = document.createElement(containerId)..id = containerId;

    document.body!.appendChild(target);
  } else {
    while (target.children.length > 0) {
      target.removeChild(target.children.item(0)!);
    }
  }

  target.appendChild(element);
}
