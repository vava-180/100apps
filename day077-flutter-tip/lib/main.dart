// 100apps Day077: チップ計算（Flutter）
// 飲食代とチップ率（%）から、チップ額・合計・1人あたりを計算する。
// スライダーでの割合入力と、リアルタイム計算（入力のたびに再計算）を学びます。

import 'package:flutter/material.dart';

void main() {
  runApp(const TipApp());
}

class TipApp extends StatelessWidget {
  const TipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'チップ計算',
      theme: ThemeData(colorSchemeSeed: Colors.amber, useMaterial3: true),
      home: const TipPage(),
    );
  }
}

class TipPage extends StatefulWidget {
  const TipPage({super.key});

  @override
  State<TipPage> createState() => _TipPageState();
}

class _TipPageState extends State<TipPage> {
  final TextEditingController _billController = TextEditingController();
  double _tipPercent = 15; // チップ率（初期15%）
  int _people = 1; // 人数

  @override
  void dispose() {
    _billController.dispose();
    super.dispose();
  }

  // 入力された飲食代（数字でなければ0）。マイナスは0として扱う。
  double get _bill {
    final v = double.tryParse(_billController.text.trim()) ?? 0;
    return v < 0 ? 0 : v;
  }
  double get _tip => _bill * _tipPercent / 100;
  double get _total => _bill + _tip;
  double get _perPerson => _people > 0 ? _total / _people : _total;

  // 金額を「1,234.56」のように小数2桁＋3桁区切りで表示する。
  String _money(double value) {
    final fixed = value.toStringAsFixed(2); // 例: "1234.56"
    final parts = fixed.split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '${buffer.toString()}.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('チップ計算')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _billController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '飲食代',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
              // 入力のたびに再計算して表示を更新する。
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // チップ率スライダー
            Row(
              children: [
                const Text('チップ率'),
                Expanded(
                  child: Slider(
                    value: _tipPercent,
                    min: 0,
                    max: 30,
                    divisions: 30,
                    label: '${_tipPercent.round()}%',
                    onChanged: (v) => setState(() => _tipPercent = v),
                  ),
                ),
                Text('${_tipPercent.round()}%'),
              ],
            ),
            // 人数の増減
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('人数', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 16),
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove),
                  onPressed: _people > 1
                      ? () => setState(() => _people -= 1)
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_people 人',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _people += 1),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // 結果（常に表示・リアルタイム更新）
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _row('チップ額', _money(_tip)),
                    const Divider(),
                    _row('合計', _money(_total)),
                    const Divider(),
                    _row('1人あたり', _money(_perPerson), big: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ラベルと金額を左右に並べる小さな行（big=true で強調）。
  Widget _row(String label, String value, {bool big = false}) {
    final style = TextStyle(
      fontSize: big ? 24 : 16,
      fontWeight: big ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$ $value', style: style),
        ],
      ),
    );
  }
}
