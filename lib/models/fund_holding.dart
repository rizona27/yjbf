// lib/models/fund_holding.dart
// 基金持仓数据结构
import 'package:intl/intl.dart';

class FundHolding {
  String clientName;
  String clientID;
  String fundCode;
  String fundName;
  double purchaseAmount;
  double purchaseShares;
  DateTime purchaseDate;
  String? remarks; // 将 remarks 字段改为可空类型
  double currentNav;
  DateTime navDate;
  bool isValid;

  FundHolding({
    required this.clientName,
    required this.clientID,
    required this.fundCode,
    required this.fundName,
    required this.purchaseAmount,
    required this.purchaseShares,
    required this.purchaseDate,
    this.remarks, // 在构造函数中也改为可空
    required this.currentNav,
    required this.navDate,
    this.isValid = false,
  });

  // 动态计算属性（Getter）
  // ... (其余代码保持不变) ...

  /// 计算总市值
  double get totalValue {
    if (currentNav >= 0 && purchaseShares >= 0) {
      return currentNav * purchaseShares;
    }
    return 0.0;
  }

  /// 计算收益
  double get profit {
    return totalValue - purchaseAmount;
  }

  /// 计算收益率
  double get profitRate {
    if (purchaseAmount > 0) {
      return (profit / purchaseAmount) * 100;
    }
    return 0.0;
  }

  /// 计算持有天数
  int get daysHeld {
    final now = DateTime.now();
    final difference = now.difference(purchaseDate);
    return difference.inDays;
  }

  // 格式化输出属性，与客户端代码保持一致
  String get latestNetValue => currentNav.toStringAsFixed(4);
  String get netValueDate => DateFormat('MM-dd').format(navDate);
  String get formattedPurchaseDate => DateFormat('yy-MM-dd').format(purchaseDate);

  // 静态方法：方便创建无效的基金持仓对象
  static FundHolding invalid({required String fundCode}) {
    return FundHolding(
      clientName: "",
      clientID: "",
      fundCode: fundCode,
      fundName: "未加载",
      purchaseAmount: 0.0,
      purchaseShares: 0.0,
      purchaseDate: DateTime.now(),
      remarks: null,
      currentNav: 0.0,
      navDate: DateTime.now(),
      isValid: false,
    );
  }

  // 新增：实现 copyWith 方法来解决报错
  FundHolding copyWith({
    String? clientName,
    String? clientID,
    String? fundCode,
    String? fundName,
    double? purchaseAmount,
    double? purchaseShares,
    DateTime? purchaseDate,
    String? remarks,
    double? currentNav,
    DateTime? navDate,
    bool? isValid,
  }) {
    return FundHolding(
      clientName: clientName ?? this.clientName,
      clientID: clientID ?? this.clientID,
      fundCode: fundCode ?? this.fundCode,
      fundName: fundName ?? this.fundName,
      purchaseAmount: purchaseAmount ?? this.purchaseAmount,
      purchaseShares: purchaseShares ?? this.purchaseShares,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      remarks: remarks ?? this.remarks,
      currentNav: currentNav ?? this.currentNav,
      navDate: navDate ?? this.navDate,
      isValid: isValid ?? this.isValid,
    );
  }
}