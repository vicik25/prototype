import 'package:flutter/services.dart';

Future<Uint8List?> readBytesFromPath(String? path) async {
  if (path == null || path.isEmpty) return null;
  final byteData = await NetworkAssetBundle(Uri.parse(path)).load(path);
  return byteData.buffer.asUint8List();
}
