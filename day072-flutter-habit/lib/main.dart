// 100apps Day072: 習慣トラッカー（Flutter）
// 続けたい習慣を登録し、「今日やった」を押すと達成回数が増えていく。
// 達成の合計回数（積み上げ）を見て、継続のモチベーションにします。
// ※データはアプリ内（メモリ）に保持するため、アプリを終了すると消えます。

import 'package:flutter/material.dart';

void main() {
  runApp(const HabitApp());
}

// 1つの習慣（名前・今日やったか・通算の達成回数）。
class Habit {
  String name;
  bool doneToday;
  int total;
  Habit(this.name, {this.doneToday = false, this.total = 0});
}

class HabitApp extends StatelessWidget {
  const HabitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '習慣トラッカー',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const HabitPage(),
    );
  }
}

class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Habit> _habits = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addHabit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _habits.add(Habit(text));
      _controller.clear();
    });
  }

  // 「今日やった」を切り替える。やった→通算+1、取り消し→通算-1。
  void _toggleToday(int index) {
    setState(() {
      final h = _habits[index];
      if (h.doneToday) {
        h.doneToday = false;
        if (h.total > 0) h.total -= 1;
      } else {
        h.doneToday = true;
        h.total += 1;
      }
    });
  }

  void _removeHabit(int index) {
    setState(() => _habits.removeAt(index));
  }

  // 「今日の達成」を全部リセットする（翌日用。通算回数は残す）。
  void _resetToday() {
    setState(() {
      for (final h in _habits) {
        h.doneToday = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = _habits.where((h) => h.doneToday).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('習慣トラッカー'),
        actions: [
          // 今日のチェックをまとめてリセット
          IconButton(
            tooltip: '今日の達成をリセット',
            icon: const Icon(Icons.refresh),
            onPressed: _habits.isEmpty ? null : _resetToday,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '習慣を入力（例: 運動、読書）',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addHabit(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addHabit, child: const Text('追加')),
              ],
            ),
          ),
          if (_habits.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '今日の達成：$doneCount / ${_habits.length} 件',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: _habits.isEmpty
                ? const Center(child: Text('続けたい習慣を追加しましょう'))
                : ListView.separated(
                    itemCount: _habits.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final h = _habits[index];
                      return ListTile(
                        leading: IconButton(
                          icon: Icon(
                            h.doneToday
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: h.doneToday ? Colors.green : Colors.grey,
                          ),
                          onPressed: () => _toggleToday(index),
                        ),
                        title: Text(h.name),
                        subtitle: Text('通算 ${h.total} 回'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeHabit(index),
                        ),
                        onTap: () => _toggleToday(index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
