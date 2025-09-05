import 'package:flutter/material.dart';

// 基金持仓数据结构
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