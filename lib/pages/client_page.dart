import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/data_manager.dart';
import '../models/fund_holding.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 使用 Consumer 来监听 DataManager 的变化
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        // 如果没有数据，显示提示信息
        if (dataManager.holdings.isEmpty) {
          return const Center(
            child: Text('没有数据，请先导入', style: TextStyle(fontSize: 16)),
          );
        }

        // 如果有数据，则使用 ListView 显示
        return ListView.builder(
          itemCount: dataManager.holdings.length,
          itemBuilder: (context, index) {
            final FundHolding holding = dataManager.holdings[index];
            return ListTile(
              title: Text('客户：${holding.clientName}'),
              subtitle: Text('基金代码：${holding.fundCode}'),
              trailing: Text('金额：${holding.purchaseAmount.toStringAsFixed(2)}'),
            );
          },
        );
      },
    );
  }
}