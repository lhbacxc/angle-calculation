/// 历史记录条目模型
class HistoryEntry {
  final int? id;
  final String expression; // 计算表达式，如 "11°22'33\" - 80°55'66\""
  final String result; // 计算结果
  final DateTime timestamp; // 时间戳

  HistoryEntry({
    this.id,
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'expression': expression,
      'result': result,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// 从数据库Map创建
  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'],
      expression: map['expression'],
      result: map['result'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  /// 复制并修改
  HistoryEntry copyWith({
    int? id,
    String? expression,
    String? result,
    DateTime? timestamp,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      expression: expression ?? this.expression,
      result: result ?? this.result,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
