import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/data_manager.dart';
import '../widgets/custom_card.dart';

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final totalAssets = dataManager.totalAssets;
        final totalProfit = dataManager.totalProfit;
        final totalClients = dataManager.totalClients;
        final isPrivacyMode = dataManager.isPrivacyMode;

        // 格式化金额，如果处于隐私模式则模糊显示
        String formatAmount(double amount) {
          if (isPrivacyMode) {
            return '******';
          }
          final formatter = NumberFormat('#,##0.00', 'en_US');
          return formatter.format(amount);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('一览'),
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isPrivacyMode),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: '总资产 (元)',
                        value: formatAmount(totalAssets),
                        color: Colors.blue.shade100,
                        icon: Icons.attach_money,
                        iconColor: Colors.blue.shade800,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: '总盈利 (元)',
                        value: formatAmount(totalProfit),
                        color: Colors.green.shade100,
                        icon: Icons.trending_up,
                        iconColor: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        title: '总客户数',
                        value: isPrivacyMode ? '***' : totalClients.toString(),
                        color: Colors.purple.shade100,
                        icon: Icons.people_outline,
                        iconColor: Colors.purple.shade800,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard(
                        title: '总持仓数',
                        value: isPrivacyMode ? '***' : dataManager.holdings.length.toString(),
                        color: Colors.orange.shade100,
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  '资产分布',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                // TODO: 饼图/柱状图展示资产分布
                // 例如：
                // PieChartWidget(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isPrivacyMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '总览数据',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            isPrivacyMode
                ? const Icon(Icons.lock_outline, color: Colors.grey)
                : const Icon(Icons.lock_open, color: Colors.green)
          ],
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('yyyy年MM月dd日').format(DateTime.now()),
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required Color iconColor,
  }) {
    return CustomCard(
      title: title,
      description: null, // 将值作为子组件传递
      backgroundColor: color,
      foregroundColor: iconColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}