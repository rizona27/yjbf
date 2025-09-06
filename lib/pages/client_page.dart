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

  // 根据主题和种子生成渐变，达到融入背景的高级感效果
  Gradient _generateGradient(BuildContext context, String seed) {
    final random = Random(seed.hashCode);
    final double hue = random.nextDouble() * 360; // 0-360度色相

    // 亮度模式（浅色/深色）
    final Brightness brightness = Theme.of(context).brightness;
    Color startColor;
    Color endColor;

    if (brightness == Brightness.light) {
      // 浅色模式：从活泼的浅色渐变到背景色
      final double saturation = random.nextDouble() * 0.2 + 0.5; // 饱和度在0.5-0.7之间
      final double lightness = random.nextDouble() * 0.1 + 0.7; // 亮度在0.7-0.8之间
      startColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
      endColor = Theme.of(context).scaffoldBackgroundColor;
    } else {
      // 深色模式：从独特的暗色渐变到背景色
      final double saturation = random.nextDouble() * 0.2 + 0.2; // 饱和度在0.2-0.4之间
      final double lightness = random.nextDouble() * 0.1 + 0.3; // 亮度在0.3-0.4之间
      startColor = HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
      endColor = Theme.of(context).scaffoldBackgroundColor;
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
      // 汉字占2个长度，其他字符占1个
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
    // 准备显示的姓名和客户号
    final String clientName = widget.isPrivacyMode
        ? widget.clientName
        : widget.holdings.first.clientName;
    final String clientID = widget.holdings.first.clientID;

    // 根据隐私模式和姓名长度决定显示的文本
    final String displayName = widget.isPrivacyMode
        ? _getTruncatedName(clientName)
        : _getTruncatedName(clientName.isNotEmpty ? clientName : clientID);

    final String displayClientID = widget.isPrivacyMode ? '' : clientID;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                gradient: _generateGradient(context, clientID),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black.withOpacity(0.08)
                        : Colors.white.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                            text: displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (displayClientID.isNotEmpty)
                            TextSpan(
                              text: ' ($displayClientID)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.normal,
                                color: Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Text(
                        '持仓${widget.holdings.length}支',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.blue.shade800,
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
              opacity: _isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Offstage(
                offstage: !_isExpanded,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
                  child: Column(
                    children: widget.holdings.map((holding) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: HoldingCard(
                          holding: holding,
                          showReportActions: true,
                          showManagementActions: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}