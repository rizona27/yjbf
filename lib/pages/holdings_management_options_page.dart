import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../widgets/custom_card.dart';
import 'add_holding_page.dart';
import 'manage_holdings_page.dart';

class HoldingsManagementOptionsPage extends StatelessWidget {
  const HoldingsManagementOptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dataManager = Provider.of<DataManager>(context, listen: false);

    void showClearConfirmationDialog() {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('清空所有持仓'),
            content: const Text('此操作将永久删除所有持仓数据，确定要继续吗？'),
            actions: <Widget>[
              TextButton(
                child: const Text('取消'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('确定', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  dataManager.clearAllHoldings();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('所有持仓数据已清空。')),
                  );
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('持仓管理'),
        backgroundColor: Colors.purple.shade400,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomCard(
              title: '新增持仓',
              description: '手动录入新的持仓记录',
              icon: Icons.add,
              backgroundColor: Colors.green.shade50,
              foregroundColor: Colors.green,
              isCompact: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AddHoldingPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            CustomCard(
              title: '管理持仓',
              description: '查看、编辑和删除持仓记录',
              icon: Icons.account_balance_wallet,
              backgroundColor: Colors.blue.shade50,
              foregroundColor: Colors.blue,
              isCompact: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ManageHoldingsPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            CustomCard(
              title: '清空持仓',
              description: '删除所有持仓数据',
              icon: Icons.delete_forever,
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
              isCompact: true,
              onTap: showClearConfirmationDialog,
            ),
          ],
        ),
      ),
    );
  }
}