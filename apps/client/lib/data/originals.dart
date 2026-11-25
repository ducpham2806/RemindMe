import 'dart:io';
import 'dart:typed_data';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Bản gốc của tệp đã nhập, giữ trên máy (Free: bản gốc chỉ nằm trên máy, pricing-entitlements `max_originals_mb`).
/// Không đồng bộ, không gửi đi; nằm trong thư mục riêng của app. Đăng xuất / xóa tài khoản / đổi tài khoản thì xóa hết.
abstract interface class OriginalsStore {
  Future<void> save(String importId, String fileName, Uint8List bytes);
  /// Tên tệp gốc của lần nhập, null nếu không có trên máy này.
  Future<String?> nameOf(String importId);
  /// Mở bằng app của hệ điều hành; false nếu không mở được.
  Future<bool> open(String importId);
  Future<void> clear();
}

class FileOriginalsStore implements OriginalsStore {
  FileOriginalsStore({Future<Directory> Function()? root}) : _root = root ?? getApplicationSupportDirectory;
  final Future<Directory> Function() _root;

  Future<Directory> _dir([String? importId]) async {
    final base = Directory('${(await _root()).path}/originals');
    return importId == null ? base : Directory('${base.path}/${_safe(importId)}');
  }

  /// Chỉ giữ ký tự an toàn cho tên tệp (không có '/', '..').
  static String _safe(String s) {
    final t = s.replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), '_').trim();
    return t.isEmpty || t == '.' || t == '..' ? 'file' : t;
  }

  Future<File?> _file(String importId) async {
    final d = await _dir(importId);
    if (!await d.exists()) return null;
    await for (final e in d.list()) {
      if (e is File) return e;
    }
    return null;
  }

  @override
  Future<void> save(String importId, String fileName, Uint8List bytes) async {
    final d = await _dir(importId);
    await d.create(recursive: true);
    await File('${d.path}/${_safe(fileName)}').writeAsBytes(bytes, flush: true);
  }

  @override
  Future<String?> nameOf(String importId) async => (await _file(importId))?.uri.pathSegments.last;

  @override
  Future<bool> open(String importId) async {
    final f = await _file(importId);
    if (f == null) return false;
    return (await OpenFilex.open(f.path)).type == ResultType.done;
  }

  @override
  Future<void> clear() async {
    final d = await _dir();
    if (await d.exists()) await d.delete(recursive: true);
  }
}

/// Bộ nhớ cho test.
class MemoryOriginalsStore implements OriginalsStore {
  final files = <String, (String, Uint8List)>{};
  final opened = <String>[];

  @override
  Future<void> save(String importId, String fileName, Uint8List bytes) async => files[importId] = (fileName, bytes);
  @override
  Future<String?> nameOf(String importId) async => files[importId]?.$1;
  @override
  Future<bool> open(String importId) async {
    if (!files.containsKey(importId)) return false;
    opened.add(importId);
    return true;
  }

  @override
  Future<void> clear() async => files.clear();
}
