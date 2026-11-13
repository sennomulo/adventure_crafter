export 'file_transfer_stub.dart'
    if (dart.library.io) 'file_transfer_io.dart'
    if (dart.library.html) 'file_transfer_web.dart';
