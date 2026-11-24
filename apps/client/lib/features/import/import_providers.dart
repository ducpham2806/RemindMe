import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'import_decode.dart';

/// Tệp người dùng chọn (tên + nội dung).
typedef PickedFile = ({String name, Uint8List bytes});

/// Mở bộ chọn tệp của hệ điều hành; null nếu hủy. Test override bằng tệp mẫu.
final filePickerProvider = Provider<Future<PickedFile?> Function()>((ref) => () async {
      final f = await FilePicker.pickFile();
      if (f == null) return null;
      return (name: f.name, bytes: await f.readAsBytes());
    });

/// Giải mã ngoài UI isolate (xlsx 5.000 dòng ~0,5 s). Test override để chạy đồng bộ trong fake-async.
final importDecoderProvider =
    Provider<Future<ImportPreview> Function(ImportRequest)>((ref) => (req) => Isolate.run(() => decodeImport(req)));
