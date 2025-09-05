import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../models/fund_holding.dart';

class HoldingCard extends StatelessWidget {
  final FundHolding holding;
  final bool showReportActions;
  final bool showManagementActions;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HoldingCard({
    Key? key,
    required this.holding,
    this.showReportActions = true,
    this.showManagementActions = false,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  String getShortenedFundName(String name) {
    if (name.length > 6) {
      return '${name.substring(0, 6)}...';
    }
    return name;
  }

  Color getProfitColor(double profit) {
    if (profit > 0) {
      return Colors.red;
    } else if (profit < 0) {
      return Colors.green;
    } else {
      return Colors.black;
    }
  }

  String formatNumber(double value) {
    final formatter = NumberFormat('#,##0.00', 'zh_CN');
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseAmount = holding.purchaseAmount / 10000;
    final profitColor = getProfitColor(holding.profit);
    final profitRateColor = getProfitColor(holding.profitRate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // First row: Fund name (code) / Latest net value (date)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${getShortenedFundName(holding.fundName)}(${holding.fundCode})',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${holding.latestNetValue} (${holding.netValueDate})',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second row: Purchase amount / Purchase shares
            Row(
              children: [
                Text('购买金额:', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${purchaseAmount.toStringAsFixed(0)}万',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 24),
                Text('购买份额:', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${holding.purchaseShares.toStringAsFixed(0)}份',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Third row: Profit / Profit rate
            Row(
              children: [
                Text('收益: ', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${holding.profit > 0 ? '+' : ''}${formatNumber(holding.profit)}元',
                  style: TextStyle(
                    color: profitColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 24),
                Text('收益率: ', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${holding.profitRate > 0 ? '+' : ''}${holding.profitRate.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: profitRateColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Fourth row: Purchase date / Days held
            Row(
              children: [
                Text('购买日期: ', style: TextStyle(color: Colors.grey[600])),
                Text(
                  holding.formattedPurchaseDate,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 24),
                Text('持有天数: ', style: TextStyle(color: Colors.grey[600])),
                Text(
                  '${holding.daysHeld}天',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            // Action buttons row
            if (showReportActions || showManagementActions) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // 所有按钮统一靠右对齐
                children: [
                  // 左侧操作按钮
                  if (showReportActions)
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            final reportContent = '''${holding.fundName} | ${holding.fundCode}
├ 购买日期:${holding.formattedPurchaseDate}
├ 持有天数:${holding.daysHeld}天
├ 购买金额:${purchaseAmount.toStringAsFixed(0)}万
├ 最新净值:${holding.latestNetValue} | ${holding.netValueDate}
├ 收益:${holding.profit > 0 ? '+' : ''}${formatNumber(holding.profit)}
└ 收益率:${holding.profitRate > 0 ? '+' : ''}${holding.profitRate.toStringAsFixed(2)}%''';
                            Clipboard.setData(ClipboardData(text: reportContent));
                            Fluttertoast.showToast(
                              msg: "报告已复制到剪贴板",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.black54,
                              textColor: Colors.white,
                            );
                          },
                          child: const Text('报告'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: holding.clientID));
                            Fluttertoast.showToast(
                              msg: "客户号已复制",
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                              backgroundColor: Colors.black54,
                              textColor: Colors.white,
                            );
                          },
                          child: const Text('复制客户号'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  // 右侧管理按钮
                  if (showManagementActions)
                    Row(
                      children: [
                        GestureDetector(
                          onTap: onEdit,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Icon(Icons.edit, color: Colors.blue, size: 20),
                          ),
                        ),
                        GestureDetector(
                          onTap: onDelete,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: Icon(Icons.delete, color: Colors.red, size: 20),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
