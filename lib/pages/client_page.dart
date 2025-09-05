import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../services/data_manager.dart';
import '../models/fund_holding.dart';
import '../widgets/holding_card.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  _ClientsPageState createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  late FToast fToast;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DataManager>(context, listen: false).refreshHoldings();
            },
          ),
        ],
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          if (dataManager.holdings.isEmpty) {
            return const Center(
              child: Text('没有数据，请先导入', style: TextStyle(fontSize: 16)),
            );
          }

          final Map<String, List<FundHolding>> groupedHoldings =
          dataManager.groupHoldingsByClient();

          return ListView.builder(
            itemCount: groupedHoldings.length,
            itemBuilder: (context, index) {
              final clientName = groupedHoldings.keys.elementAt(index);
              final holdings = groupedHoldings[clientName]!;
              final displayClientName = dataManager.isPrivacyMode
                  ? dataManager.getObscuredClientID(holdings.first.clientID)
                  : clientName;

              return ExpandableClientCard(
                clientName: displayClientName,
                holdings: holdings,
                isPrivacyMode: dataManager.isPrivacyMode,
              );
            },
          );
        },
      ),
    );
  }
}

class ExpandableClientCard extends StatefulWidget {
  final String clientName;
  final List<FundHolding> holdings;
  final bool isPrivacyMode;

  const ExpandableClientCard({
    super.key,
    required this.clientName,
    required this.holdings,
    required this.isPrivacyMode,
  });

  @override
  _ExpandableClientCardState createState() => _ExpandableClientCardState();
}

class _ExpandableClientCardState extends State<ExpandableClientCard> {
  bool _isExpanded = false;

  String _getGroupTitle(String clientKey, List<FundHolding> holdings) {
    final firstHolding = holdings.first;
    if (firstHolding.clientName.isNotEmpty) {
      return '${firstHolding.clientName} (${firstHolding.clientID})';
    }
    return '${firstHolding.clientID} (${firstHolding.clientID})';
  }

  // 调整了饱和度和亮度范围，生成更活泼的颜色
  Color _generateMorandiColor(String seed) {
    final random = Random(seed.hashCode);
    final double hue = random.nextDouble() * 360;
    final double saturation = random.nextDouble() * 0.3 + 0.4;
    final double lightness = random.nextDouble() * 0.2 + 0.7;

    return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final endColor = isDarkMode ? Colors.black : Colors.white;

    return Card(
      elevation: _isExpanded ? 4 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    _generateMorandiColor(widget.holdings.first.clientID),
                    endColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getGroupTitle(widget.holdings.first.clientID, widget.holdings),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.blue.shade800,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: widget.holdings.map((holding) {
                  return HoldingCard(
                    holding: holding,
                    showReportActions: true,
                    showManagementActions: false,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
