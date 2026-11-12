import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/history_entry.dart';

/// 历史记录导出服务
class ExportService {
  /// 获取导出目录（优先使用 Downloads 目录）
  static Future<Directory> _getExportDirectory() async {
    // Android 10+ 推荐使用应用专属的外部存储目录
    // 这个目录不需要存储权限，且用户可以通过文件管理器访问
    final directory = await getExternalStorageDirectory();
    if (directory == null) {
      throw Exception('无法访问存储目录');
    }

    // 在应用的外部存储目录下创建 Exports 文件夹
    final exportDir = Directory('${directory.path}/Exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir;
  }

  /// 导出历史记录为CSV文件
  static Future<String> exportToCSV(List<HistoryEntry> entries) async {
    final directory = await _getExportDirectory();

    // 创建文件名（带时间戳）
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/angle_history_$timestamp.csv';

    // 生成CSV内容
    final buffer = StringBuffer();
    buffer.writeln('计算表达式,计算结果,时间');

    for (var entry in entries) {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp);
      buffer.writeln('"${entry.expression}","${entry.result}","$time"');
    }

    // 写入文件
    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return filePath;
  }

  /// 导出历史记录为TXT文件
  static Future<String> exportToTXT(List<HistoryEntry> entries) async {
    final directory = await _getExportDirectory();

    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final filePath = '${directory.path}/angle_history_$timestamp.txt';

    final buffer = StringBuffer();
    buffer.writeln('===== 角度计算历史记录 =====\n');

    for (var entry in entries) {
      final time = DateFormat('yyyy-MM-dd HH:mm:ss').format(entry.timestamp);
      buffer.writeln('时间: $time');
      buffer.writeln('表达式: ${entry.expression}');
      buffer.writeln('结果: ${entry.result}');
      buffer.writeln('---');
    }

    final file = File(filePath);
    await file.writeAsString(buffer.toString());

    return filePath;
  }
}
