// 100apps Day087: 単語帳（フラッシュカード）（Flutter）
// 「表（問題）」と「裏（答え）」のカードを登録し、タップでめくって覚える。
// カードの「現在位置」と「表裏」を状態として持つ方法を学びます。
// ※データはアプリ内（メモリ）に保持するため、アプリを終了すると消えます。

import 'package:flutter/material.dart';

void main() {
  runApp(const FlashcardApp());
}

// 1枚のカード（表＝問題、裏＝答え）。
class Card2 {
  final String front;
  final String back;
  Card2(this.front, this.back);
}

class FlashcardApp extends StatelessWidget {
  const FlashcardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '単語帳',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const FlashcardPage(),
    );
  }
}

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  // 最初から数枚入れておく（使い方が分かりやすいように）。
  final List<Card2> _cards = [
    Card2('apple', 'りんご'),
    Card2('water', '水'),
    Card2('study', '勉強する'),
  ];
  int _index = 0; // 今見ているカードの番号
  bool _showBack = false; // true=裏（答え）を表示中

  // カード追加ダイアログ用の入力。
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _flip() {
    setState(() => _showBack = !_showBack);
  }

  // 前後に移動する（移動したら表に戻す）。範囲を超えないよう丸める。
  void _move(int delta) {
    if (_cards.isEmpty) return;
    setState(() {
      _index = (_index + delta).clamp(0, _cards.length - 1);
      _showBack = false;
    });
  }

  // 追加ダイアログを開く。
  Future<void> _openAddDialog() async {
    _frontController.clear();
    _backController.clear();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('カードを追加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _frontController,
                decoration: const InputDecoration(labelText: '表（問題）'),
              ),
              TextField(
                controller: _backController,
                decoration: const InputDecoration(labelText: '裏（答え）'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () {
                final front = _frontController.text.trim();
                final back = _backController.text.trim();
                if (front.isEmpty || back.isEmpty) return;
                setState(() {
                  _cards.add(Card2(front, back));
                  _index = _cards.length - 1; // 追加したカードへ移動
                  _showBack = false;
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('単語帳')),
        body: const Center(child: Text('カードがありません')),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddDialog,
          child: const Icon(Icons.add),
        ),
      );
    }

    final card = _cards[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('単語帳')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${_index + 1} / ${_cards.length} 枚',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            // カード本体（タップでめくる）
            Expanded(
              child: GestureDetector(
                onTap: _flip,
                child: Card(
                  color: _showBack
                      ? Colors.blue.shade50
                      : Colors.white,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _showBack ? '裏（答え）' : '表（問題）',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _showBack ? card.back : card.front,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'タップでめくる',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 前へ／次へ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _index > 0 ? () => _move(-1) : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('前へ'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _index < _cards.length - 1 ? () => _move(1) : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('次へ'),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
