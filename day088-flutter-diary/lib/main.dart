// 100apps Day088: 日記（Flutter）
// その日のひとことを書いて保存し、日付つきで一覧表示する。気分（顔）も選べる。
// 「日時の自動付与」と「一覧の新しい順表示」を学びます。
// ※データはアプリ内（メモリ）に保持するため、アプリを終了すると消えます。

import 'package:flutter/material.dart';

void main() {
  runApp(const DiaryApp());
}

// 日記1件（日時・気分の絵文字・本文）。
class DiaryEntry {
  final DateTime date;
  final String mood;
  final String text;
  DiaryEntry(this.date, this.mood, this.text);
}

class DiaryApp extends StatelessWidget {
  const DiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '日記',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const DiaryPage(),
    );
  }
}

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final TextEditingController _controller = TextEditingController();
  final List<DiaryEntry> _entries = []; // 先頭が最新
  static const List<String> _moods = ['😀', '🙂', '😐', '😢', '😡'];
  String _selectedMood = '🙂';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今日のひとことを書いてください')),
      );
      return;
    }
    setState(() {
      _entries.insert(0, DiaryEntry(DateTime.now(), _selectedMood, text));
      _controller.clear();
    });
  }

  void _remove(int index) {
    setState(() => _entries.removeAt(index));
  }

  // 日付を「2026/6/23(火) 14:05」のように表示する。
  String _fmtDate(DateTime d) {
    const week = ['月', '火', '水', '木', '金', '土', '日'];
    String two(int n) => n.toString().padLeft(2, '0');
    final w = week[d.weekday - 1]; // weekdayは月=1〜日=7
    return '${d.year}/${d.month}/${d.day}($w) ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('日記')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 気分の選択
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final mood in _moods)
                      GestureDetector(
                        onTap: () => setState(() => _selectedMood = mood),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selectedMood == mood
                                ? Colors.green.withValues(alpha: 0.25)
                                : Colors.transparent,
                          ),
                          child: Text(
                            mood,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '今日のひとこと',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text('保存する'),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 日記の一覧（新しい順）
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('まだ日記がありません'))
                : ListView.separated(
                    itemCount: _entries.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final e = _entries[index];
                      return ListTile(
                        leading: Text(
                          e.mood,
                          style: const TextStyle(fontSize: 28),
                        ),
                        title: Text(e.text),
                        subtitle: Text(_fmtDate(e.date)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _remove(index),
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
