import 'dart:async';
import 'package:http/http.dart' as http;

/// Web 平台文件加载实现
class FileLoader {
  /// 从指定路径加载文件内容（使用 HTTP GET）
  static Future<String> loadFileAsString(String path) async {
    try {
      Uri uri = Uri.parse(path);
      if (!uri.hasScheme) {
        uri = Uri.base.resolve(path);
      }

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception("Failed to load file from ${uri.toString()}: HTTP ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Failed to load file from $path: $e");
    }
  }
}
