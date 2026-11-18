import 'dart:typed_data';

import 'package:file_picker/file_picker.dart' as fp;

import 'file_bytes_stub.dart' if (dart.library.io) 'file_bytes_io.dart';

Future<Uint8List?> readPlatformFileBytes(fp.PlatformFile file) async {
  final dyn = file as dynamic;

  // 1. Cek properti data (Uint8List atau List<int>)
  try {
    final data = dyn.data;
    if (data is Uint8List && data.isNotEmpty) {
      return data;
    }
    if (data is List<int> && data.isNotEmpty) {
      return Uint8List.fromList(data);
    }
  } catch (_) {}

  // 2. Cek properti xFile (standar file_picker versi web modern)
  try {
    final xFile = dyn.xFile;
    if (xFile != null) {
      final bytes = await xFile.readAsBytes();
      if (bytes is Uint8List && bytes.isNotEmpty) {
        return bytes;
      }
      if (bytes is List<int> && bytes.isNotEmpty) {
        return Uint8List.fromList(bytes);
      }
    }
  } catch (_) {}

  // 3. Cek properti readStream jika berkas dibaca sebagai stream
  try {
    final stream = dyn.readStream;
    if (stream != null) {
      final chunks = <int>[];
      await for (final chunk in stream) {
        chunks.addAll(List<int>.from(chunk));
      }
      if (chunks.isNotEmpty) {
        return Uint8List.fromList(chunks);
      }
    }
  } catch (_) {}

  // 4. Fallback untuk platform Android/iOS/Desktop
  return readBytesFromPath(file.path);
}
