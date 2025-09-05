import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../models/fund_holding.dart';
import 'fund_service.dart';

class DataManager extends ChangeNotifier {
  bool _isPrivacyMode = false;
  bool get isPrivacyMode => _isPrivacyMode;

  List<FundHolding> holdings = [];

  // 移除了 final 关键字，并使用 late 声明，使其可变
  late FundService fundService;

  DataManager({required this.fundService});

  double get totalAssets {
    return holdings.fold(0.0, (sum, holding) => sum + holding.purchaseAmount);
  }

  double get totalProfit {
    return totalAssets * 0.1;
  }

  int get totalClients {
    return holdings.map((h) => h.clientID).toSet().length;
  }

  void togglePrivacyMode() {
    _isPrivacyMode = !_isPrivacyMode;
    notifyListeners();
  }

  void saveData() {
    debugPrint('数据已保存');
  }

  Future<String> importData() async {
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
        return _processCsvData(fileContent);
      } else {
        fundService.addLog("导入已取消。", type: 'warning');
        return "导入已取消。";
      }
    } catch (e) {
      fundService.addLog("导入失败: $e", type: 'error');
      return "导入失败：$e";
    }
  }

  Future<String> importFromAssets(String assetPath) async {
    try {
      final fileContent = await rootBundle.loadString(assetPath);
      return _processCsvData(fileContent);
    } catch (e) {
      fundService.addLog("从 assets 导入失败: $e", type: 'error');
      return "从 assets 导入失败：$e";
    }
  }

  Future<String> _processCsvData(String fileContent) async {
    const converter = CsvToListConverter(
      fieldDelimiter: ',',
    );
    final List<List<dynamic>> csvData = converter.convert(fileContent);

    if (csvData.isEmpty || csvData.length < 2) {
      fundService.addLog("导入失败：CSV文件为空或只有标题行。", type: 'error');
      return "导入失败：CSV文件为空或只有标题行。";
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
      fundService.addLog("导入失败：缺少必要的列 (${missingRequiredHeaders.join(', ')})", type: 'error');
      return "导入失败：缺少必要的列 (${missingRequiredHeaders.join(', ')})";
    }

    final existingHoldingsSet = holdings.toSet();
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
        holdings.add(newHolding);
        importedCount++;
        fundService.addLog("导入记录: $clientName-$fundCode 金额: $purchaseAmount 份额: $purchaseShares", type: 'info');
      } else {
        fundService.addLog("跳过重复记录: $clientName-$fundCode", type: 'info');
      }
    }
    saveData();
    fundService.addLog("导入完成: 成功导入 $importedCount 条记录", type: 'success');
    notifyListeners();
    return "导入成功：$importedCount 条记录。";
  }

  Future<String> exportData() async {
    final DateFormat dateFormatter = DateFormat('yyyy-MM-dd');
    final List<List<dynamic>> csvRows = [
      ['客户姓名', '基金代码', '购买金额', '购买份额', '购买日期', '客户号', '备注']
    ];

    for (var holding in holdings) {
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
        fundService.addLog("导出成功: $path", type: 'success');
        return "导出成功：文件已保存到 $path";
      } else {
        return "导出已取消。";
      }
    } catch (e) {
      fundService.addLog("导出失败: $e", type: 'error');
      return "导出失败：$e";
    }
  }
}