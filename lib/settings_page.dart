import 'package:flutter/material.dart';
import 'custom_card.dart';
import 'data_service.dart'; // 导入新的数据服务文件

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // 实例化数据服务
  final DataService _dataService = DataService();

  // 隐私模式的当前选择
  int _selectedPrivacyIndex = 0; // 0: 开启, 1: 关闭
  // 主题模式的当前选择
  int _selectedThemeIndex = 0; // 0: 浅色, 1: 深色, 2: 系统

  @override
  void initState() {
    super.initState();
    // 可以在这里初始化模拟数据
    _dataService.dataManager.holdings.add(
      FundHolding(
        clientName: '张三',
        clientID: '123456789012',
        fundCode: '001234',
        purchaseAmount: 1000.00,
        purchaseShares: 100.00,
        purchaseDate: DateTime(2023, 1, 15),
        remarks: '首次购买',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      onTap: () => _dataService.importData(context), // 调用新服务
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
                      onTap: () => _dataService.exportData(context), // 调用新服务
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
                        // TODO: 实现管理持仓逻辑
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
                        // TODO: 实现日志查询逻辑
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
                      onTap: () {
                        // TODO: 触摸事件逻辑
                      },
                      child: _buildSegmentedControl(
                        ['开启', '关闭'],
                        _selectedPrivacyIndex,
                            (index) {
                          setState(() {
                            _selectedPrivacyIndex = index;
                          });
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
                      onTap: () {
                        // TODO: 触摸事件逻辑
                      },
                      child: _buildSegmentedControl(
                        ['浅色', '深色', '系统'],
                        _selectedThemeIndex,
                            (index) {
                          setState(() {
                            _selectedThemeIndex = index;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomCard(
                title: '关于',
                description: '程序版本信息和说明',
                icon: Icons.info,
                backgroundColor: Colors.lightBlue.shade50,
                foregroundColor: Colors.lightBlue,
                onTap: () {
                  // TODO: 实现关于页面的跳转逻辑
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
  }

  // 保持 _buildSegmentedControl 在 SettingsPage 中
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
}

// 虚线和渐变文字组件也可以保留在这里，或者单独创建文件，取决于你的偏好
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