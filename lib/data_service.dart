import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

// 模拟你的 FundHolding 数据结构
class FundHolding {
  String clientName;
  String clientID;
  String fundCode;
  double purchaseAmount;
  double purchaseShares;
  DateTime purchaseDate;
  String remarks;

  FundHolding({
    required this.clientName,
    required this.clientID,
    required this.fundCode,
    required this.purchaseAmount,
    required this.purchaseShares,
    required this.purchaseDate,
    required this.remarks,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is FundHolding &&
              runtimeType == other.runtimeType &&
              clientName == other.clientName &&
              clientID == other.clientID &&
              fundCode == other.fundCode &&
              purchaseAmount == other.purchaseAmount &&
              purchaseShares == other.purchaseShares &&
              purchaseDate.year == other.purchaseDate.year &&
              purchaseDate.month == other.purchaseDate.month &&
              purchaseDate.day == other.purchaseDate.day &&
              remarks == other.remarks;

  @override
  int get hashCode =>
      clientName.hashCode ^
      clientID.hashCode ^
      fundCode.hashCode ^
      purchaseAmount.hashCode ^
      purchaseShares.hashCode ^
      purchaseDate.day.hashCode ^
      remarks.hashCode;
}

// 模拟你的数据管理器和日志服务
class DataManager {
  List<FundHolding> holdings = [];
  void saveData() {
    // 模拟保存数据
    debugPrint('数据已保存');
  }
}

class FundService {
  void addLog(String message, {required String type}) {
    debugPrint('[$type] $message');
  }
}

// 负责所有数据处理的服务类
class DataService {
  final DataManager dataManager = DataManager();
  final FundService fundService = FundService();

  // 导入数据逻辑
  Future<void> importData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        final fileContent = await file.readAsString();

        const converter = CsvToListConverter(
          fieldDelimiter: ',',
        );
        final List<List<dynamic>> csvData = converter.convert(fileContent);

        if (csvData.isEmpty || csvData.length < 2) {
          _showSnackBar(context, "导入失败：CSV文件为空或只有标题行。");
          return;
        }

        final headers = csvData[0].map((e) => e.toString().trim()).toList();

        final columnMapping = {
          '客户姓名': ['客户姓名', '姓名'],
          '基金代码': ['基金代码', '代码'],
          '购买金额': ['购买金额', '持仓成本（元）', '持仓成本', '成本'],
          '购买份额': ['购买份额', '当前份额', '份额'],
          '购买日期': ['购买日期', '最早购买日期', '日期'],
          '客户号': ['客户号', '核心客户号'],
          '备注': ['备注']
        };

        var columnIndices = <String, int>{};
        var missingRequiredHeaders = <String>[];

        for (var entry in columnMapping.entries) {
          var found = false;
          for (var alias in entry.value) {
            final index = headers.indexWhere((h) => h.contains(alias));
            if (index != -1) {
              columnIndices[entry.key] = index;
              found = true;
              break;
            }
          }
          if (!found &&
              ['基金代码', '购买金额', '购买份额', '客户号'].contains(entry.key)) {
            missingRequiredHeaders.add(entry.key);
          }
        }

        if (missingRequiredHeaders.isNotEmpty) {
          _showSnackBar(
              context, "导入失败：缺少必要的列 (${missingRequiredHeaders.join(', ')})");
          return;
        }

        final existingHoldingsSet = dataManager.holdings.toSet();
        int importedCount = 0;
        final DateFormat dateFormat = DateFormat('yyyy-MM-dd');

        for (int i = 1; i < csvData.length; i++) {
          final row = csvData[i];
          if (row.length < headers.length) continue;

          String clientName = '';
          if (columnIndices.containsKey('客户姓名')) {
            clientName = row[columnIndices['客户姓名']!].toString().trim();
          }

          String clientID = '';
          if (columnIndices.containsKey('客户号')) {
            clientID = row[columnIndices['客户号']!].toString().trim();
            if (clientID.isEmpty) continue;
            clientID = clientID.padLeft(12, '0');
          } else {
            continue;
          }

          String fundCode = '';
          if (columnIndices.containsKey('基金代码')) {
            fundCode = row[columnIndices['基金代码']!].toString().trim();
            if (fundCode.isEmpty) continue;
            fundCode = fundCode.padLeft(6, '0');
          } else {
            continue;
          }

          double purchaseAmount = 0.0;
          if (columnIndices.containsKey('购买金额')) {
            purchaseAmount = double.tryParse(row[columnIndices['购买金额']!].toString().trim()) ?? 0.0;
          } else {
            continue;
          }

          double purchaseShares = 0.0;
          if (columnIndices.containsKey('购买份额')) {
            purchaseShares = double.tryParse(row[columnIndices['购买份额']!].toString().trim()) ?? 0.0;
          } else {
            continue;
          }

          DateTime purchaseDate = DateTime.now();
          if (columnIndices.containsKey('购买日期')) {
            try {
              purchaseDate = dateFormat.parse(row[columnIndices['购买日期']!].toString().trim());
            } catch (e) {
              // 如果日期格式不正确，则使用当前日期
            }
          }

          String remarks = '';
          if (columnIndices.containsKey('备注')) {
            remarks = row[columnIndices['备注']!].toString().trim();
          }

          if (clientName.isEmpty) {
            clientName = clientID;
          }

          final newHolding = FundHolding(
            clientName: clientName,
            clientID: clientID,
            fundCode: fundCode,
            purchaseAmount: purchaseAmount,
            purchaseShares: purchaseShares,
            purchaseDate: purchaseDate,
            remarks: remarks,
          );

          if (!existingHoldingsSet.contains(newHolding)) {
            dataManager.holdings.add(newHolding);
            importedCount++;
            fundService.addLog("导入记录: $clientName-$fundCode 金额: $purchaseAmount 份额: $purchaseShares", type: 'info');
          } else {
            fundService.addLog("跳过重复记录: $clientName-$fundCode", type: 'info');
          }
        }
        dataManager.saveData();
        fundService.addLog("导入完成: 成功导入 $importedCount 条记录", type: 'success');
        _showSnackBar(context, "导入成功：$importedCount 条记录。");
      } else {
        // 用户取消了选择
        _showSnackBar(context, "导入已取消。");
      }
    } catch (e) {
      _showSnackBar(context, "导入失败：$e");
      fundService.addLog("导入失败: $e", type: 'error');
    }
  }

  // 导出数据逻辑
  Future<void> exportData(BuildContext context) async {
    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
    final List<List<dynamic>> csvRows = [
      ['客户姓名', '基金代码', '购买金额', '购买份额', '购买日期', '客户号', '备注']
    ];

    for (var holding in dataManager.holdings) {
      csvRows.add([
        holding.clientName,
        holding.fundCode,
        holding.purchaseAmount.toStringAsFixed(2),
        holding.purchaseShares.toStringAsFixed(2),
        dateFormatter.format(holding.purchaseDate),
        holding.clientID,
        holding.remarks,
      ]);
    }

    final String csvString = const ListToCsvConverter().convert(csvRows);
    final fileName = "${dateFormatter.format(DateTime.now())}数据导出.csv";

    try {
      final String? path = await FilePicker.platform.saveFile(
        fileName: fileName,
      );

      if (path != null) {
        final file = File(path);
        await file.writeAsString(csvString);
        _showSnackBar(context, "导出成功：文件已保存到 $path");
        fundService.addLog("导出成功: $path", type: 'success');
      } else {
        // 用户取消了保存
        _showSnackBar(context, "导出已取消。");
      }
    } catch (e) {
      _showSnackBar(context, "导出失败：$e");
      fundService.addLog("导出失败: $e", type: 'error');
    }
  }

  // 显示 SnackBar 的辅助函数
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}