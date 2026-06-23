// 100apps Day079: 為替計算（Flutter）
// レート（1ドル＝何円か）を手で入力し、金額を「円⇄ドル」で変換する。
// ※ネット通信はしません。レートは自分で入力する方式（外部API不使用）。

import 'package:flutter/material.dart';

void main() {
  runApp(const CurrencyApp());
}

class CurrencyApp extends StatelessWidget {
  const CurrencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '為替計算',
      theme: ThemeData(colorSchemeSeed: Colors.lightGreen, useMaterial3: true),
      home: const CurrencyPage(),
    );
  }
}

class CurrencyPage extends StatefulWidget {
  const CurrencyPage({super.key});

  @override
  State<CurrencyPage> createState() => _CurrencyPageState();
}

class _CurrencyPageState extends State<CurrencyPage> {
  final TextEditingController _rateController =
      TextEditingController(text: '150'); // 1ドル＝何円（初期150）
  final TextEditingController _amountController = TextEditingController();
  bool _yenToUsd = true; // true=円→ドル, false=ドル→円

  @override
  void dispose() {
    _rateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double get _rate => double.tryParse(_rateController.text.trim()) ?? 0;
  double? get _amount => double.tryParse(_amountController.text.trim());

  // 変換結果。レートが0以下、金額が空・マイナスなら null。
  double? get _result {
    final amount = _amount;
    if (amount == null || amount < 0 || _rate <= 0) return null;
    // 円→ドルは「円 ÷ レート」、ドル→円は「ドル × レート」。
    return _yenToUsd ? amount / _rate : amount * _rate;
  }

  String _money(double v) {
    final fixed = v.toStringAsFixed(2);
    final parts = fixed.split('.');
    final buffer = StringBuffer();
    final intPart = parts[0];
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()}.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final fromLabel = _yenToUsd ? '円' : 'ドル';
    final toLabel = _yenToUsd ? 'ドル' : '円';

    return Scaffold(
      appBar: AppBar(title: const Text('為替計算')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // レート手入力（ネット通信はしない）
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'レート（1ドル＝◯円）',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            // 変換方向の切り替え
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('円 → ドル')),
                ButtonSegment(value: false, label: Text('ドル → 円')),
              ],
              selected: {_yenToUsd},
              onSelectionChanged: (s) =>
                  setState(() => _yenToUsd = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: '金額（$fromLabel）',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('変換結果（$toLabel）',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      result == null ? '—' : '${_money(result)} $toLabel',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '※レートは手入力です（ネット通信はしません）',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
