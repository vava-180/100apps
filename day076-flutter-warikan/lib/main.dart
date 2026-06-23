// 100apps Day076: 割り勘（Flutter）
// 合計金額と人数から「1人あたり」を計算する。端数は切り上げて集める方式。
// 整数の割り算・切り上げ（余りの扱い）と、合計とのズレの表示を学びます。

import 'package:flutter/material.dart';

void main() {
  runApp(const WarikanApp());
}

class WarikanApp extends StatelessWidget {
  const WarikanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '割り勘',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const WarikanPage(),
    );
  }
}

class WarikanPage extends StatefulWidget {
  const WarikanPage({super.key});

  @override
  State<WarikanPage> createState() => _WarikanPageState();
}

class _WarikanPageState extends State<WarikanPage> {
  final TextEditingController _totalController = TextEditingController();
  int _people = 2; // 人数（初期は2人）
  int? _total; // 確定した合計金額（未計算は null）

  @override
  void dispose() {
    _totalController.dispose();
    super.dispose();
  }

  // 派生値（1人あたり・集まり・おつり）は保存せず、その都度計算する。
  // こうすると人数を変えても古い結果が残らず、常に正しい値になる。

  // 1人あたり（100円単位で切り上げ）。未計算なら null。
  int? get _perPerson {
    final total = _total;
    if (total == null) return null;
    final raw = total / _people; // 割った値（小数）
    return (raw / 100).ceil() * 100; // 100円単位に切り上げ
  }

  // 集まる合計（1人あたり × 人数）。
  int? get _collected {
    final per = _perPerson;
    return per == null ? null : per * _people;
  }

  // おつり（集まり − 合計）。
  int? get _change {
    final total = _total;
    final collected = _collected;
    if (total == null || collected == null) return null;
    return collected - total;
  }

  void _calc() {
    final total = int.tryParse(_totalController.text.trim());
    if (total == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('合計金額を正しい数字で入力してください')),
      );
      return;
    }
    setState(() => _total = total);
  }

  String _yen(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '¥${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    final per = _perPerson;

    return Scaffold(
      appBar: AppBar(title: const Text('割り勘')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _totalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '合計金額（円）',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _calc(),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _calc,
                child: const Text('計算する'),
              ),
            ),
            const SizedBox(height: 24),
            if (per != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('1人あたり（100円単位）',
                          style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        _yen(per),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text('集まる合計：${_yen(_collected!)}'),
                      Text('おつり：${_yen(_change!)}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
