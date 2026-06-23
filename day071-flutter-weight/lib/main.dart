// 100apps Day071: 体重記録（Flutter）
// 体重を入力して記録し、最新の値と「前回との差」を表示する簡単な記録アプリ。
// 小数の入力（double.tryParse）と、前回データとの比較を学びます。
// ※データはアプリ内（メモリ）に保持するため、アプリを終了すると消えます。

import 'package:flutter/material.dart';

void main() {
  runApp(const WeightApp());
}

// 1件の記録（記録した日時と体重kg）。
class WeightLog {
  final DateTime date;
  final double kg;
  WeightLog(this.date, this.kg);
}

class WeightApp extends StatelessWidget {
  const WeightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '体重記録',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const WeightPage(),
    );
  }
}

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  final TextEditingController _controller = TextEditingController();
  // 新しい記録を先頭に入れる（[0]が最新）。
  final List<WeightLog> _logs = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 入力をチェックして1件追加する。
  void _addLog() {
    final kg = double.tryParse(_controller.text.trim());
    if (kg == null || kg <= 0 || kg > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正しい体重（0〜500kg）を入力してください')),
      );
      return;
    }
    setState(() {
      _logs.insert(0, WeightLog(DateTime.now(), kg));
      _controller.clear();
    });
  }

  void _removeLog(int index) {
    setState(() => _logs.removeAt(index));
  }

  // 日付を「6/23 14:05」のように短く表示する。
  String _fmtDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.month}/${d.day} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final latest = _logs.isEmpty ? null : _logs.first;
    // 前回（2番目に新しい記録）との差を計算する。
    final double? diff = _logs.length >= 2 ? _logs[0].kg - _logs[1].kg : null;

    return Scaffold(
      appBar: AppBar(title: const Text('体重記録')),
      body: Column(
        children: [
          // 最新の体重と前回差を表示するカード
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('最新の体重', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(
                    latest == null
                        ? '— kg'
                        : '${latest.kg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (diff != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '前回比 ${diff >= 0 ? '+' : ''}${diff.toStringAsFixed(1)} kg',
                      style: TextStyle(
                        fontSize: 16,
                        color: diff > 0
                            ? Colors.red
                            : (diff < 0 ? Colors.blue : Colors.grey),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // 入力エリア
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: '体重（kg）',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addLog(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addLog, child: const Text('記録')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 記録の一覧
          Expanded(
            child: _logs.isEmpty
                ? const Center(child: Text('記録はまだありません'))
                : ListView.separated(
                    itemCount: _logs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      return ListTile(
                        leading: const Icon(Icons.monitor_weight_outlined),
                        title: Text('${log.kg.toStringAsFixed(1)} kg'),
                        subtitle: Text(_fmtDate(log.date)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeLog(index),
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
