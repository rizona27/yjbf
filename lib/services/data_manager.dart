import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:math';

import '../models/fund_holding.dart';
import 'fund_service.dart';

class DataManager extends ChangeNotifier {
  bool _isPrivacyMode = false;
  bool get isPrivacyMode => _isPrivacyMode;

  List<FundHolding> holdings = [];

  late FundService fundService;

  DataManager({required this.fundService});

  // 基金持仓数据管理方法
  /// 新增一个持仓
  void addHolding(FundHolding newHolding) {
    holdings.add(newHolding);
    notifyListeners();
  }

  /// 更新一个持仓
  void updateHolding(FundHolding updatedHolding) {
    final index = holdings.indexWhere((h) => h.clientID == updatedHolding.clientID && h.fundCode == updatedHolding.fundCode);
    if (index != -1) {
      holdings[index] = updatedHolding;
      notifyListeners();
    }
  }

  /// 删除一个指定的持仓
  void deleteHolding(String holdingId) {
    holdings.removeWhere((h) => h.clientID == holdingId);
    notifyListeners();
  }

  /// 批量修改客户名
  void batchRename(String oldName, String newName) {
    for (var i = 0; i < holdings.length; i++) {
      if (holdings[i].clientName == oldName) {
        holdings[i] = holdings[i].copyWith(clientName: newName);
      }
    }
    notifyListeners();
  }

  /// 批量删除某个客户的所有持仓
  void batchDelete(String clientName) {
    holdings.removeWhere((h) => h.clientName == clientName);
    notifyListeners();
  }

  /// 清空所有持仓数据
  void clearAllHoldings() {
    holdings.clear();
    notifyListeners();
  }

  // 隐私模式相关
  /// 生成一个唯一的混淆ID，解决隐私模式下姓名冲突问题
  String getObscuredClientID(String clientID) {
    if (clientID.isEmpty) {
      return '';
    }
    // 使用简单的哈希函数生成一个唯一的混淆字符串
    var bytes = utf8.encode(clientID);
    var hash = 0;
    for (var i = 0; i < bytes.length; i++) {
      hash = (hash << 5) - hash + bytes[i];
      hash = hash & hash; // Ensure it's a 32-bit integer
    }
    return hash.toUnsigned(32).toRadixString(16).padLeft(8, '0');
  }

  String obscuredName(String name) {
    if (!_isPrivacyMode || name.isEmpty) {
      return name;
    }
    // 获取对应的客户号并返回混淆ID
    try {
      final holding = holdings.firstWhere((h) => h.clientName == name);
      return getObscuredClientID(holding.clientID);
    } catch (e) {
      return name;
    }
  }

  void togglePrivacyMode() {
    _isPrivacyMode = !_isPrivacyMode;
    notifyListeners();
  }

  // 数据计算与分组
  /// 新增：按客户姓名分组持仓数据
  Map<String, List<FundHolding>> groupHoldingsByClient() {
    final Map<String, List<FundHolding>> namedGroups = {};
    final Map<String, List<FundHolding>> unnamedGroups = {};

    for (var holding in holdings) {
      if (holding.clientName.isNotEmpty) {
        if (namedGroups.containsKey(holding.clientName)) {
          namedGroups[holding.clientName]!.add(holding);
        } else {
          namedGroups[holding.clientName] = [holding];
        }
      } else {
        if (unnamedGroups.containsKey(holding.clientID)) {
          unnamedGroups[holding.clientID]!.add(holding);
        } else {
          unnamedGroups[holding.clientID] = [holding];
        }
      }
    }

    // 按姓名（拼音）排序
    final sortedNamedKeys = namedGroups.keys.toList()..sort((a, b) => a.compareTo(b));
    // 按客户号数字升序排序
    final sortedUnnamedKeys = unnamedGroups.keys.toList()..sort((a, b) {
      final aInt = int.tryParse(a) ?? 0;
      final bInt = int.tryParse(b) ?? 0;
      return aInt.compareTo(bInt);
    });

    final Map<String, List<FundHolding>> finalGroupedHoldings = {};
    for (var key in sortedNamedKeys) {
      finalGroupedHoldings[key] = namedGroups[key]!;
    }
    for (var key in sortedUnnamedKeys) {
      finalGroupedHoldings[key] = unnamedGroups[key]!;
    }

    return finalGroupedHoldings;
  }

  double get totalAssets {
    return holdings.fold(0.0, (sum, holding) => sum + holding.purchaseAmount);
  }

  double get totalProfit {
    return holdings.fold(0.0, (sum, holding) => sum + holding.profit);
  }

  int get totalClients {
    return holdings.map((h) => h.clientID).toSet().length;
  }

  void saveData() {
    debugPrint('数据已保存');
  }

  // 基金信息更新
  /// 新增：刷新所有基金持仓的净值
  Future<void> refreshHoldings() async {
    fundService.addLog('开始刷新所有基金持仓...', type: 'info');
    for (var holding in holdings) {
      final updatedHolding = await fundService.fetchFundInfo(holding.fundCode);
      if (updatedHolding.isValid) {
        holding.fundName = updatedHolding.fundName;
        holding.currentNav = updatedHolding.currentNav;
        holding.navDate = updatedHolding.navDate;
        holding.isValid = updatedHolding.isValid;
      }
    }
    notifyListeners();
    fundService.addLog('基金持仓刷新完成。', type: 'success');
  }

  // 文件导入/导出
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

    // --- 新增：使用所有字段进行严格的重复项校验 ---
    // 创建一个集合来存储现有记录的唯一哈希值
    final existingRecordHashes = <String>{};
    final DateFormat fullDateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (var holding in holdings) {
      final recordHash = '${holding.clientName},${holding.clientID},${holding.fundCode},${holding.purchaseAmount},'
          '${holding.purchaseShares},${fullDateFormat.format(holding.purchaseDate)},${holding.remarks}';
      existingRecordHashes.add(recordHash);
    }

    int importedCount = 0;
    int duplicateCount = 0;
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

      // 生成当前记录的哈希值，包含所有关键字段
      final newRecordHash = '$clientName,$clientID,$fundCode,$purchaseAmount,'
          '$purchaseShares,${fullDateFormat.format(purchaseDate)},$remarks';

      // 检查哈希值是否已存在，进行重复项判断
      if (existingRecordHashes.contains(newRecordHash)) {
        duplicateCount++;
        fundService.addLog("跳过重复记录: $clientName-$fundCode", type: 'info');
      } else {
        final newHolding = FundHolding(
          clientName: clientName,
          clientID: clientID,
          fundCode: fundCode,
          purchaseAmount: purchaseAmount,
          purchaseShares: purchaseShares,
          purchaseDate: purchaseDate,
          remarks: remarks,
          fundName: '未加载',
          currentNav: 0.0,
          navDate: DateTime.now(),
        );

        holdings.add(newHolding);
        existingRecordHashes.add(newRecordHash);
        importedCount++;
        fundService.addLog("导入记录: $clientName-$fundCode 金额: $purchaseAmount 份额: $purchaseShares", type: 'info');
      }
    }
    saveData();
    fundService.addLog("导入完成: 成功导入 $importedCount 条记录，跳过 $duplicateCount 条重复记录", type: 'success');
    notifyListeners();
    return "导入成功：$importedCount 条记录，跳过 $duplicateCount 条重复记录。";
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
