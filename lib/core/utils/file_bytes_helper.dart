import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;

import 'file_bytes_stub.dart' if (dart.library.io) 'file_bytes_io.dart';

Future<Uint8List?> readPlatformFileBytes(fp.PlatformFile file) async {
  try {
    final dyn = file as dynamic;
    if (dyn.data != null && dyn.data is Uint8List) {
      return dyn.data as Uint8List;
    }
  } catch (_) {}

  return readBytesFromPath(file.path);
}
