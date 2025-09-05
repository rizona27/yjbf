import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/fund_holding.dart';
import '../services/data_manager.dart';

class AddHoldingPage extends StatefulWidget {
  const AddHoldingPage({super.key});

  @override
  State<AddHoldingPage> createState() => _AddHoldingPageState();
}

class _AddHoldingPageState extends State<AddHoldingPage> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _clientIDController = TextEditingController();
  final _fundCodeController = TextEditingController();
  final _fundNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _sharesController = TextEditingController();
  final _remarksController = TextEditingController();
  DateTime? _purchaseDate;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _purchaseDate) {
      setState(() {
        _purchaseDate = picked;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (_purchaseDate == null) {
        _showSnackBar('请选择购买日期', isError: true);
        return;
      }
      final newHolding = FundHolding(
        clientName: _clientNameController.text.trim(),
        clientID: _clientIDController.text.trim().isEmpty ? UniqueKey().toString() : _clientIDController.text.trim(),
        fundCode: _fundCodeController.text.trim(),
        fundName: _fundNameController.text.trim(),
        purchaseAmount: double.parse(_amountController.text),
        purchaseShares: double.parse(_sharesController.text),
        purchaseDate: _purchaseDate!,
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        currentNav: 0.0,
        navDate: DateTime.now(),
        isValid: true,
      );

      final dataManager = Provider.of<DataManager>(context, listen: false);
      dataManager.addHolding(newHolding);
      _showSnackBar('持仓信息新增成功！');
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _clientIDController.dispose();
    _fundCodeController.dispose();
    _fundNameController.dispose();
    _amountController.dispose();
    _sharesController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新增持仓'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _clientNameController,
                decoration: const InputDecoration(labelText: '客户姓名*'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '客户姓名不能为空';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fundCodeController,
                decoration: const InputDecoration(labelText: '基金代码*'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '基金代码不能为空';
                  }
                  if (value.length != 6 || int.tryParse(value) == null) {
                    return '基金代码必须是6位纯数字';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _fundNameController,
                decoration: const InputDecoration(labelText: '基金名称*'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '基金名称不能为空';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: '购买金额*'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,10}(\.\d{0,2})?'))],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '购买金额不能为空';
                  }
                  final parsedValue = double.tryParse(value);
                  if (parsedValue == null) {
                    return '请输入有效的金额';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _sharesController,
                decoration: const InputDecoration(labelText: '购买份额*'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,10}(\.\d{0,2})?'))],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '购买份额不能为空';
                  }
                  final parsedValue = double.tryParse(value);
                  if (parsedValue == null) {
                    return '请输入有效的份额';
                  }
                  return null;
                },
              ),
              ListTile(
                title: Text(
                  _purchaseDate == null
                      ? '购买日期*'
                      : '购买日期: ${_purchaseDate!.year}-${_purchaseDate!.month}-${_purchaseDate!.day}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              TextFormField(
                controller: _clientIDController,
                decoration: const InputDecoration(labelText: '客户号 (可选)'),
                keyboardType: TextInputType.text,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]'))],
              ),
              TextFormField(
                controller: _remarksController,
                decoration: const InputDecoration(labelText: '备注 (可选)'),
                maxLength: 10,
                validator: (value) {
                  if (value != null && value.trim().runes.length > 10) {
                    return '备注不得超过10个汉字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
