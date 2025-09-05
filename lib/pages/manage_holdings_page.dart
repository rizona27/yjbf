import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/fund_holding.dart';
import '../widgets/holding_card.dart';
import 'edit_holding_page.dart';
import 'dart:math';

class ManageHoldingsPage extends StatefulWidget {
  const ManageHoldingsPage({super.key});

  @override
  State<ManageHoldingsPage> createState() => _ManageHoldingsPageState();
}

class _ManageHoldingsPageState extends State<ManageHoldingsPage> {
  // 用于存储每个分组的展开状态
  final Map<String, bool> _isExpanded = {};

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<String?> _showRenameDialog(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('批量修改客户名'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '新客户名'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('管理持仓'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Consumer<DataManager>(
        builder: (context, dataManager, child) {
          final groupedData = dataManager.groupHoldingsByClient();
          final groupedEntries = groupedData.entries.toList();

          if (groupedEntries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('暂无持仓数据，请先新增或导入。', style: TextStyle(color: Colors.grey)),
              ),
            );
          }

          return ListView.builder(
            itemCount: groupedEntries.length,
            itemBuilder: (context, index) {
              final entry = groupedEntries[index];
              final clientKey = entry.key;
              final holdings = entry.value;
              final isExpanded = _isExpanded[clientKey] ?? false;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded[clientKey] = !isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Container(
                              // 调整垂直填充为 4，与 client_page 保持一致
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: [
                                    _generateMorandiColor(clientKey),
                                    endColor,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _getGroupTitle(clientKey, holdings),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : Colors.black,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // 使用 GestureDetector 和 Text 替换 TextButton
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () async {
                                          final newName = await _showRenameDialog(context, holdings.first.clientName);
                                          if (newName != null && newName.isNotEmpty) {
                                            dataManager.batchRename(holdings.first.clientName, newName);
                                            _showSnackBar('客户名批量修改成功');
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                          child: Text(
                                            '批量改名',
                                            style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      GestureDetector(
                                        onTap: () {
                                          dataManager.batchDelete(holdings.first.clientName);
                                          _showSnackBar('客户 ${holdings.first.clientName} 的所有持仓已删除');
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                                          child: Text(
                                            '批量删除',
                                            style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.red.shade300 : Colors.red.shade800, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(
                              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: AnimatedOpacity(
                        opacity: isExpanded ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Offstage(
                          offstage: !isExpanded,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 32.0, top: 4.0, right: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: holdings.map((holding) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: HoldingCard(
                                  holding: holding,
                                  showReportActions: false,
                                  showManagementActions: true,
                                  onEdit: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => EditHoldingPage(holding: holding),
                                      ),
                                    );
                                  },
                                  onDelete: () {
                                    dataManager.deleteHolding(holding.clientID);
                                    _showSnackBar('持仓已删除');
                                  },
                                ),
                              )).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}