import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remindme_data/remindme_data.dart' show LocalPrefs;

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

/// Cách ghép cột đã nhớ (LocalPrefs `table_mappings`: JSON chữ ký header → mapping). Chỉ có tên trường và số cột, không có nội dung ô.
const tableMappingsPref = 'table_mappings';
const _maxTableMappings = 50;

Future<Map<String, String>> loadTableMappings(LocalPrefs prefs) async {
  final raw = await prefs.get(tableMappingsPref);
  if (raw == null) return const {};
  try {
    return {for (final e in (jsonDecode(raw) as Map).entries) e.key as String: e.value as String};
  } on Object {
    return const {};
  }
}

/// Ghi (hoặc xóa khi [json] null) cách ghép của 1 chữ ký; giữ tối đa 50 bản, bỏ bản cũ nhất.
Future<void> saveTableMapping(LocalPrefs prefs, String signature, String? json) async {
  final all = Map<String, String>.of(await loadTableMappings(prefs))..remove(signature);
  if (json != null) all[signature] = json;
  while (all.length > _maxTableMappings) {
    all.remove(all.keys.first);
  }
  await prefs.set(tableMappingsPref, jsonEncode(all));
}
