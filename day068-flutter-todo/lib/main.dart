// 100apps Day068: ToDoアプリ（Flutter）
// やることを追加し、チェックで「完了」、不要なら削除できる定番アプリ。
// 「データのまとまり（クラス）」をリストで持ち、状態を更新する練習です。
// ※データはアプリ内（メモリ）に保持するため、アプリを終了すると消えます。

import 'package:flutter/material.dart';

void main() {
  runApp(const TodoApp());
}

// 1件のやること（文章と、完了したかどうか）。
class Task {
  String title;
  bool done;
  Task(this.title, {this.done = false});
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDoリスト',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const TodoPage(),
    );
  }
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Task> _tasks = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTask() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _tasks.add(Task(text));
      _controller.clear();
    });
  }

  // チェックの ON/OFF を切り替える。
  void _toggle(int index, bool? value) {
    setState(() => _tasks[index].done = value ?? false);
  }

  void _removeTask(int index) {
    setState(() => _tasks.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    // 残り（未完了）の件数を数える
    final remaining = _tasks.where((t) => !t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDoリスト'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text('残り $remaining 件 / 全 ${_tasks.length} 件'),
          ),
        ),
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
                      hintText: 'やることを入力',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addTask, child: const Text('追加')),
              ],
            ),
          ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(child: Text('やることはまだありません'))
                : ListView.separated(
                    itemCount: _tasks.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return CheckboxListTile(
                        value: task.done,
                        onChanged: (v) => _toggle(index, v),
                        title: Text(
                          task.title,
                          // 完了したら取り消し線を引く
                          style: TextStyle(
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : null,
                            color: task.done ? Colors.grey : null,
                          ),
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeTask(index),
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
