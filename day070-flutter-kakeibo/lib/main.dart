// 100apps Day070: 家計簿（Flutter）
// 「収入」「支出」を内容と金額で記録し、合計（残高）を上に表示する簡単家計簿。
// 入力した金額の合計を計算して表示する＝数値の集計とフォーマットの練習です。
// ※データはアプリ内（メモリ）に保持するため、アプリを終了すると消えます。

import 'package:flutter/material.dart';

void main() {
  runApp(const KakeiboApp());
}

// 1件の記録（内容・金額・支出かどうか）。
class Entry {
  final String title;
  final int amount; // 円（プラスの整数で持つ）
  final bool isExpense; // true=支出, false=収入
  Entry(this.title, this.amount, this.isExpense);
}

class KakeiboApp extends StatelessWidget {
  const KakeiboApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '家計簿',
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const KakeiboPage(),
    );
  }
}

class KakeiboPage extends StatefulWidget {
  const KakeiboPage({super.key});

  @override
  State<KakeiboPage> createState() => _KakeiboPageState();
}

class _KakeiboPageState extends State<KakeiboPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final List<Entry> _entries = [];
  bool _isExpense = true; // 入力中の種類（初期は支出）

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // 内容と金額を確認して1件追加する。
  void _addEntry() {
    final title = _titleController.text.trim();
    final amount = int.tryParse(_amountController.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容と、正しい金額（1以上の数字）を入力してください')),
      );
      return;
    }
    setState(() {
      _entries.insert(0, Entry(title, amount, _isExpense));
      _titleController.clear();
      _amountController.clear();
    });
  }

  void _removeEntry(int index) {
    setState(() => _entries.removeAt(index));
  }

  // 残高＝収入の合計 − 支出の合計
  int get _balance {
    var total = 0;
    for (final e in _entries) {
      total += e.isExpense ? -e.amount : e.amount;
    }
    return total;
  }

  // 3桁ごとにカンマを入れて「1,234」のように見せる（パッケージ無しの簡易版）。
  String _yen(int value) {
    final negative = value < 0;
    var digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '${negative ? '-' : ''}¥${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家計簿')),
      body: Column(
        children: [
          // 残高の表示カード
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('残高', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    _yen(_balance),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _balance < 0 ? Colors.red : Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 入力エリア（種類の切り替え・内容・金額・追加）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                // 収入／支出の切り替え
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('支出')),
                    ButtonSegment(value: false, label: Text('収入')),
                  ],
                  selected: {_isExpense},
                  onSelectionChanged: (s) =>
                      setState(() => _isExpense = s.first),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: '内容（例: 昼食、給料）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: '金額（円）',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _addEntry(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _addEntry, child: const Text('追加')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 記録の一覧
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('記録はまだありません'))
                : ListView.separated(
                    itemCount: _entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = _entries[index];
                      return ListTile(
                        leading: Icon(
                          e.isExpense
                              ? Icons.remove_circle_outline
                              : Icons.add_circle_outline,
                          color: e.isExpense ? Colors.red : Colors.green,
                        ),
                        title: Text(e.title),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${e.isExpense ? '-' : '+'}${_yen(e.amount)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: e.isExpense ? Colors.red : Colors.green,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _removeEntry(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
