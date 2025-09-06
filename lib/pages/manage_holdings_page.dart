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

  // 生成活泼、明亮的渐变色，并与背景色融合
  Gradient _generateGradient(BuildContext context, String seed) {
    final random = Random(seed.hashCode);
    final double hue = random.nextDouble() * 360;

    final Brightness brightness = Theme.of(context).brightness;
    Color startColor;
    Color endColor = Theme.of(context).scaffoldBackgroundColor;

    if (brightness == Brightness.light) {
      final double saturation = random.nextDouble() * 0.2 + 0.5;
      final double lightness = random.nextDouble() * 0.1 + 0.7;
      startColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    } else {
      final double saturation = random.nextDouble() * 0.2 + 0.2;
      final double lightness = random.nextDouble() * 0.1 + 0.3;
      startColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    }

    return LinearGradient(
      colors: [startColor, endColor],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    );
  }

  // 限制姓名长度，超过部分用...表示
  String _getTruncatedName(String name) {
    int maxLen = 8; // 8个英文字符或4个汉字
    int currentLength = 0;
    int charIndex = 0;

    for (int i = 0; i < name.length; i++) {
      final codeUnit = name.codeUnitAt(i);
      if (codeUnit >= 0x4e00 && codeUnit <= 0x9fff) {
        currentLength += 2;
      } else {
        currentLength += 1;
      }
      if (currentLength > maxLen) {
        charIndex = i;
        return '${name.substring(0, charIndex)}...';
      }
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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

              // 准备显示的姓名
              final String clientName = holdings.first.clientName;
              final String clientID = holdings.first.clientID;

              // 根据隐私模式和姓名长度决定显示的文本
              final String displayName = dataManager.isPrivacyMode
                  ? dataManager.getObscuredClientID(clientID)
                  : _getTruncatedName(clientName);

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
                      child: Container(
                        // 统一高度，使用与 ClientsPage 相同的垂直填充值
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: _generateGradient(context, clientID),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              // 将 RichText 替换为简单的 Text
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis, // 添加溢出处理
                              ),
                            ),
                            const SizedBox(width: 8),
                            // 操作按钮区域
                            Row(
                              mainAxisSize: MainAxisSize.min,
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
                                const SizedBox(width: 8),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ],
                            ),
                          ],
                        ),
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