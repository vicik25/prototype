import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readBytesFromPath(String? path) async {
  if (path == null) return null;
  return await File(path).readAsBytes();
}
