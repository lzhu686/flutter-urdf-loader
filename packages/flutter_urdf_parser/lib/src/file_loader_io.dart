import 'dart:async';
import 'dart:io';

/// Native 平台文件加载实现
class FileLoader {
  /// 从指定路径加载文件内容（使用 dart:io File API）
  static Future<String> loadFileAsString(String path) async {
    final file = File(path);
    if (await file.exists()) {
      return await file.readAsString();
    } else {
      throw Exception("File not found at $path");
    }
  }
}
