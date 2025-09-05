import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../services/data_manager.dart';
import '../widgets/custom_card.dart';
import 'log_page.dart';
import 'holdings_management_options_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedThemeIndex = 0;

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildSegmentedControl(
      List<String> options, int selectedIndex, Function(int) onOptionTapped) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onOptionTapped(index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  options[index],
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        final bool isPrivacyMode = dataManager.isPrivacyMode;

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: CustomCard(
                          title: '导入数据',
                          description: '从CSV文件导入持仓数据',
                          icon: Icons.file_download,
                          backgroundColor: Colors.orange.shade50,
                          foregroundColor: Colors.orange,
                          onTap: () async {
                            final resultMessage = await dataManager.importData();
                            _showSnackBar(context, resultMessage);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomCard(
                          title: '导出数据',
                          description: '导出持仓数据到CSV文件',
                          icon: Icons.file_upload,
                          backgroundColor: Colors.orange.shade50,
                          foregroundColor: Colors.orange,
                          onTap: () async {
                            final resultMessage = await dataManager.exportData();
                            _showSnackBar(context, resultMessage);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomCard(
                          title: '管理持仓',
                          description: '新增、编辑或清空持仓数据',
                          icon: Icons.account_balance_wallet,
                          backgroundColor: Colors.purple.shade50,
                          foregroundColor: Colors.purple,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const HoldingsManagementOptionsPage()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomCard(
                          title: '日志查询',
                          description: 'API请求与响应日志',
                          icon: Icons.history,
                          backgroundColor: Colors.blueGrey.shade50,
                          foregroundColor: Colors.blueGrey,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const LogPage()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomCard(
                          title: '隐私模式',
                          description: null,
                          icon: Icons.lock,
                          backgroundColor: Colors.lightGreen.shade50,
                          foregroundColor: Colors.lightGreen,
                          child: _buildSegmentedControl(
                            ['开启', '关闭'],
                            isPrivacyMode ? 0 : 1,
                                (index) {
                              if ((index == 0 && !isPrivacyMode) ||
                                  (index == 1 && isPrivacyMode)) {
                                dataManager.togglePrivacyMode();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomCard(
                          title: '主题模式',
                          description: null,
                          icon: Icons.color_lens,
                          backgroundColor: Colors.teal.shade50,
                          foregroundColor: Colors.teal,
                          child: _buildSegmentedControl(
                            ['浅色', '深色', '系统'],
                            _selectedThemeIndex,
                                (index) {
                              setState(() {
                                _selectedThemeIndex = index;
                              });
                              // TODO: 在这里添加实际切换主题的逻辑
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomCard(
                    title: '导入 Assets 数据',
                    description: '从assets目录导入CSV文件 (调试模式)',
                    icon: Icons.bug_report,
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                    onTap: () async {
                      final resultMessage = await dataManager.importFromAssets('assets/debug_data.csv');
                      _showSnackBar(context, resultMessage);
                    },
                  ),
                  const SizedBox(height: 20),
                  const DashedDivider(),
                  const SizedBox(height: 20),
                  GradientText(
                    'Happiness around the corner.',
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade300, Colors.blue.shade800],
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// 虚线分割线小部件
class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashSpace = 5.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Colors.grey),
              ),
            );
          }),
        );
      },
    );
  }
}

// 渐变色文本小部件
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText(
      this.text, {
        super.key,
        required this.gradient,
        this.style,
      });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}
