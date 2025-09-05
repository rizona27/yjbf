// holding_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../models/fund_holding.dart';

class HoldingCard extends StatelessWidget {
  final FundHolding holding;

  const HoldingCard({Key? key, required this.holding}) : super(key: key);

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
            // 第一行：基金名称(代码) / 净值(日期)
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
                  '最新净值:${holding.latestNetValue} (${holding.netValueDate})',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 第二行：购买金额 / 购买份额
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
            // 第三行：收益 / 收益率
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
            // 第四行：购买日期 / 持有天数
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
            const SizedBox(height: 8),
            // 第五行：按钮
            Row(
              children: [
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.description, size: 16),
                  label: const Text('报告'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('复制客户号'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}