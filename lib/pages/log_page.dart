import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/fund_service.dart';

// The LogPage is now a constant widget
class LogPage extends StatelessWidget {
  const LogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日志查询'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              // 清除日志
              Provider.of<FundService>(context, listen: false).clearLogs();
            },
          ),
        ],
      ),
      body: Consumer<FundService>(
        builder: (context, fundService, child) {
          if (fundService.logMessages.isEmpty) {
            return const Center(
              child: Text('没有日志记录', style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }
          return ListView.builder(
            itemCount: fundService.logMessages.length,
            itemBuilder: (context, index) {
              final logEntry = fundService.logMessages[index];
              final formattedTime = DateFormat('HH:mm:ss').format(logEntry.timestamp);

              Color logColor;
              switch (logEntry.type) {
                case 'success':
                  logColor = Colors.green;
                  break;
                case 'error':
                  logColor = Colors.red;
                  break;
                case 'warning':
                  logColor = Colors.amber;
                  break;
                default:
                  logColor = Colors.black;
              }

              return ListTile(
                title: Text(
                  '[$formattedTime] [${logEntry.type.toUpperCase()}] ${logEntry.message}',
                  style: TextStyle(color: logColor),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
