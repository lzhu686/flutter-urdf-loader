import 'dart:async';
import 'package:http/http.dart' as http;

/// Web 平台文件加载实现
class FileLoader {
  /// 从指定路径加载文件内容（使用 HTTP GET）
  static Future<String> loadFileAsString(String path) async {
    try {
      final response = await http.get(Uri.parse(path));
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Failed to load file from $path: HTTP ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to load file from $path: $e");
    }
  }
}
