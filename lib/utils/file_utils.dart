import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// 文件/目录工具
class FileUtils {
  FileUtils._();

  /// 离线缓存根目录：<app_doc>/downloads/
  static Future<Directory> getCacheRoot() async {
    final doc = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(doc.path, 'downloads'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// 临时目录
  static Future<Directory> getTempRoot() async {
    return getTemporaryDirectory();
  }

  /// 单曲缓存路径：downloads/<album>/<title>.<ext>
  static Future<File> songFile({
    required String album,
    required String title,
    required String ext,
  }) async {
    final root = await getCacheRoot();
    final dir = Directory(p.join(root.path, _safe(album)));
    if (!await dir.exists()) await dir.create(recursive: true);
    return File(p.join(dir.path, '${_safe(title)}.$ext'));
  }

  /// 递归统计目录大小（字节）
  static Future<int> dirSize(Directory dir) async {
    int total = 0;
    if (!await dir.exists()) return 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  /// 字节数 → 人可读字符串
  static String humanReadableSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    double size = bytes / 1024;
    int i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${units[i]}';
  }

  static String _safe(String name) {
    return name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }
}
