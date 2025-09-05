import 'package:flutter/material.dart';

// 定义日志条目的数据结构
class LogEntry {
  final String message;
  final String type;
  final DateTime timestamp;

  LogEntry({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

// 修改 FundService，使其可以被 Provider 监听
class FundService extends ChangeNotifier {
  final List<LogEntry> _logMessages = [];
  List<LogEntry> get logMessages => _logMessages;

  void addLog(String message, {required String type}) {
    final newLog = LogEntry(
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    _logMessages.add(newLog);
    // 限制日志数量，防止内存占用过多
    if (_logMessages.length > 100) {
      _logMessages.removeAt(0);
    }
    // 通知所有监听者数据已更新
    notifyListeners();
  }

  void clearLogs() {
    _logMessages.clear();
    notifyListeners();
  }
}