import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/fund_holding.dart';
import '../services/data_manager.dart';

class EditHoldingPage extends StatefulWidget {
  final FundHolding holding;
  const EditHoldingPage({super.key, required this.holding});

  @override
  State<EditHoldingPage> createState() => _EditHoldingPageState();
}

class _EditHoldingPageState extends State<EditHoldingPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clientNameController;
  late TextEditingController _clientIDController;
  late TextEditingController _fundCodeController;
  late TextEditingController _fundNameController;
  late TextEditingController _amountController;
  late TextEditingController _sharesController;
  late TextEditingController _remarksController;
  late DateTime _purchaseDate;

  @override
  void initState() {
    super.initState();
    _clientNameController = TextEditingController(text: widget.holding.clientName);
    _clientIDController = TextEditingController(text: widget.holding.clientID);
    _fundCodeController = TextEditingController(text: widget.holding.fundCode);
    _fundNameController = TextEditingController(text: widget.holding.fundName);
    _amountController = TextEditingController(text: widget.holding.purchaseAmount.toString());
    _sharesController = TextEditingController(text: widget.holding.purchaseShares.toString());
    _remarksController = TextEditingController(text: widget.holding.remarks);
    _purchaseDate = widget.holding.purchaseDate;
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
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
      final updatedHolding = widget.holding.copyWith(
        clientName: _clientNameController.text.trim(),
        clientID: _clientIDController.text.trim(),
        fundCode: _fundCodeController.text.trim(),
        fundName: _fundNameController.text.trim(),
        purchaseAmount: double.parse(_amountController.text),
        purchaseShares: double.parse(_sharesController.text),
        purchaseDate: _purchaseDate,
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      );

      final dataManager = Provider.of<DataManager>(context, listen: false);
      dataManager.updateHolding(updatedHolding);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('持仓信息修改成功！')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑持仓'),
        backgroundColor: Colors.blueAccent,
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
                  '购买日期: ${_purchaseDate.year}-${_purchaseDate.month}-${_purchaseDate.day}',
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
                child: const Text('保存修改'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
