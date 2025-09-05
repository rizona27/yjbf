// lib/services/fund_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/fund_holding.dart'; // 使用整合后的基金模型

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

class ProfitResult {
  final double absolute;
  final double annualized;

  ProfitResult({required this.absolute, required this.annualized});
}

// 修改 FundService，使其可以被 Provider 监听
class FundService extends ChangeNotifier {
  final List<LogEntry> _logMessages = [];
  List<LogEntry> get logMessages => _logMessages;

  // 新增：缓存
  final Map<String, FundHolding> _fundCache = {};
  static final DateFormat dateFormatterYYYY_MM_DD = DateFormat('yyyy-MM-dd');
  static final DateFormat dateFormatterYYYYMMDD = DateFormat('yyyyMMdd');

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

  // 计算收益和年化收益率
  ProfitResult calculateProfit(holding) {
    // 检查是否具备计算条件
    if (holding.currentNav <= 0 || holding.purchaseShares <= 0) {
      return ProfitResult(absolute: 0.0, annualized: 0.0);
    }

    // 计算持有天数
    final holdingDays = calculateHoldingDays(holding.purchaseDate);

    final currentMarketValue = holding.currentNav * holding.purchaseShares;
    final absoluteProfit = currentMarketValue - holding.purchaseAmount;

    if (holdingDays <= 0 || holding.purchaseAmount <= 0) {
      return ProfitResult(absolute: absoluteProfit, annualized: 0.0);
    }

    // 计算年化收益率 (绝对收益 / 成本 / 天数 * 365)
    final annualizedReturn = (absoluteProfit / holding.purchaseAmount) / holdingDays * 365.0;

    return ProfitResult(absolute: absoluteProfit, annualized: annualizedReturn * 100);
  }

  // 计算持有天数
  int calculateHoldingDays(DateTime purchaseDate) {
    final now = DateTime.now();
    final holdingStartDate = DateTime(purchaseDate.year, purchaseDate.month, purchaseDate.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(holdingStartDate);
    return difference.inDays + 1;
  }

  // 从API获取基金信息
  Future<FundHolding> fetchFundInfo(String fundCode) async {
    // 优先从缓存获取
    if (_fundCache.containsKey(fundCode)) {
      final cachedHolding = _fundCache[fundCode]!;
      // 如果缓存未过期（例如，同一天），则直接返回
      if (cachedHolding.navDate.day == DateTime.now().day) {
        addLog("基金代码 $fundCode: 从缓存获取", type: 'cache');
        return cachedHolding;
      }
    }

    addLog("基金代码 $fundCode: 尝试从天天基金获取最新净值...", type: 'info');
    FundHolding holding = await _fetchFromEastmoney(fundCode);
    if (holding.isValid) {
      _fundCache[fundCode] = holding;
      addLog("基金代码 $fundCode: 天天基金获取成功", type: 'success');
      return holding;
    }

    // 如果天天基金失败，尝试从腾讯财经获取
    addLog("基金代码 $fundCode: 天天基金获取失败，尝试从腾讯财经获取...", type: 'warning');
    holding = await _fetchFromTencent(fundCode);
    if (holding.isValid) {
      _fundCache[fundCode] = holding;
      addLog("基金代码 $fundCode: 腾讯财经获取成功", type: 'success');
      return holding;
    }

    addLog("基金代码 $fundCode: 所有API获取均失败", type: 'error');
    // 所有API都失败，返回一个无效的holding
    return FundHolding.invalid(fundCode: fundCode);
  }

  Future<FundHolding> _fetchFromEastmoney(String fundCode) async {
    final url = 'https://fundgz.1234567.com.cn/js/$fundCode.js';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0'
      });
      if (response.statusCode == 200) {
        // 修复乱码问题：使用 utf8.decode 解码响应体
        final rawJson = utf8.decode(response.bodyBytes).replaceAll('jsonpgz(', '').replaceAll(');', '');
        final json = jsonDecode(rawJson);
        final navDate = dateFormatterYYYY_MM_DD.parse(json['jzrq']);
        final currentNav = double.tryParse(json['gsz'] ?? json['dwjz']);

        if (currentNav != null && currentNav > 0) {
          final holding = FundHolding.invalid(fundCode: fundCode);
          holding.fundName = json['name'];
          holding.navDate = navDate;
          holding.currentNav = currentNav;
          holding.isValid = true;
          return holding;
        }
      }
    } catch (e) {
      addLog('基金代码 $fundCode: 从天天基金获取失败: $e', type: 'error');
    }
    return FundHolding.invalid(fundCode: fundCode);
  }

  Future<FundHolding> _fetchFromTencent(String fundCode) async {
    final url = 'https://web.ifzq.gtimg.cn/fund/newfund/fundSsgz/getSsgz?app=web&symbol=jj$fundCode';
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0'
      });
      if (response.statusCode == 200) {
        // 修复乱码问题：使用 utf8.decode 解码响应体
        final json = jsonDecode(utf8.decode(response.bodyBytes));
        final dataList = json['data']['data'] as List?;
        if (dataList != null && dataList.isNotEmpty) {
          final latestData = dataList.last;
          final currentNav = double.tryParse(latestData[1]);
          if (currentNav != null && currentNav > 0) {
            final holding = FundHolding.invalid(fundCode: fundCode);
            holding.fundName = json['data']['fund_name'] ?? 'N/A';
            holding.navDate = DateTime.now();
            holding.currentNav = currentNav;
            holding.isValid = true;
            return holding;
          }
        }
      }
    } catch (e) {
      addLog('基金代码 $fundCode: 从腾讯财经获取失败: $e', type: 'error');
    }
    return FundHolding.invalid(fundCode: fundCode);
  }
}