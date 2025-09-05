import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/data_manager.dart';
import '../models/fund_holding.dart';
import '../widgets/holding_card.dart';
import 'edit_holding_page.dart';
import 'package:pinyin/pinyin.dart';

class ManageHoldingsPage extends StatefulWidget {
  const ManageHoldingsPage({super.key});

  @override
  State<ManageHoldingsPage> createState() => _ManageHoldingsPageState();
}

class _ManageHoldingsPageState extends State<ManageHoldingsPage> {
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
      // 客户姓名不为空，显示姓名(客户号)
      return '${firstHolding.clientName} (${firstHolding.clientID})';
    }
    // 客户姓名为空，显示客户号(客户号)
    return '${firstHolding.clientID} (${firstHolding.clientID})';
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(16.0),
            itemCount: groupedEntries.length,
            itemBuilder: (context, index) {
              final entry = groupedEntries[index];
              final clientKey = entry.key;
              final holdings = entry.value;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              _getGroupTitle(clientKey, holdings),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final newName = await _showRenameDialog(context, holdings.first.clientName);
                                  if (newName != null && newName.isNotEmpty) {
                                    dataManager.batchRename(holdings.first.clientName, newName);
                                    _showSnackBar('客户名批量修改成功');
                                  }
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('批量改名', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  dataManager.batchDelete(holdings.first.clientName);
                                  _showSnackBar('客户 ${holdings.first.clientName} 的所有持仓已删除');
                                },
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('批量删除', style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      ...holdings.map((holding) => Row(
                        children: [
                          Expanded(child: HoldingCard(holding: holding)),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => EditHoldingPage(holding: holding),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              dataManager.deleteHolding(holding.clientID);
                              _showSnackBar('持仓已删除');
                            },
                          ),
                        ],
                      )).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}