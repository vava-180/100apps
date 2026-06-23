// 100apps Day067: メモ帳（Flutter）
// 入力欄に書いて「追加」すると一覧に並び、不要なメモは削除できる簡単メモ帳。
// 入力欄（TextField）・リスト表示（ListView）・状態更新（setState）の練習です。
// ※データはアプリ内（メモリ）に保持するため、アプリを終了すると消えます。

import 'package:flutter/material.dart';

void main() {
  runApp(const MemoApp());
}

class MemoApp extends StatelessWidget {
  const MemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'メモ帳',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const MemoPage(),
    );
  }
}

class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  // 入力欄の文字を読み取るためのコントローラー
  final TextEditingController _controller = TextEditingController();
  // メモの一覧（新しいものを上に積む）
  final List<String> _memos = [];

  @override
  void dispose() {
    _controller.dispose(); // 後片付け（メモリリーク防止）
    super.dispose();
  }

  // 入力された文字をメモに追加する。空欄なら何もしない。
  void _addMemo() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _memos.insert(0, text);
      _controller.clear();
    });
  }

  // 指定した位置のメモを削除する。
  void _removeMemo(int index) {
    setState(() => _memos.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('メモ帳')),
      body: Column(
        children: [
          // 入力欄と追加ボタン
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'メモを入力',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addMemo(), // Enterでも追加
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addMemo, child: const Text('追加')),
              ],
            ),
          ),
          // メモがゼロのときの案内／あるときは一覧表示
          Expanded(
            child: _memos.isEmpty
                ? const Center(child: Text('メモはまだありません'))
                : ListView.separated(
                    itemCount: _memos.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(_memos[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeMemo(index),
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
