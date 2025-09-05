import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/data_manager.dart';
// 修正：重新导入 CustomCard
import '../widgets/custom_card.dart';
import '../widgets/holding_card.dart';

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

        String formatAmount(double amount) {
          if (isPrivacyMode) {
            return '******';
          }
          final formatter = NumberFormat('#,##0.00', 'en_US');
          return formatter.format(amount);
        }

        String formatProfit(double amount) {
          if (isPrivacyMode) return '******';
          final formatter = NumberFormat('#,##0.00', 'en_US');
          final formatted = formatter.format(amount);
          return amount > 0 ? '+$formatted' : formatted;
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
                        value: formatProfit(totalProfit),
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
      description: null,
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