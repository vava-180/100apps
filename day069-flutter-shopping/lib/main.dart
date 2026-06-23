// 100apps Day069: 買い物リスト（Flutter）
// 買うものを追加し、買えたらチェック。「買えたものをまとめて消す」ボタン付き。
// ToDoアプリの応用で、「条件に合う要素だけまとめて削除する」操作を学びます。
// ※データはアプリ内（メモリ）に保持するため、アプリを終了すると消えます。

import 'package:flutter/material.dart';

void main() {
  runApp(const ShoppingApp());
}

// 買い物の1品（名前と、買えたかどうか）。
class Item {
  String name;
  bool bought;
  Item(this.name, {this.bought = false});
}

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '買い物リスト',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const ShoppingPage(),
    );
  }
}

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Item> _items = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _items.add(Item(text));
      _controller.clear();
    });
  }

  void _toggle(int index, bool? value) {
    setState(() => _items[index].bought = value ?? false);
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  // 「買えた（チェック済み）」の品をまとめて消す。
  void _clearBought() {
    setState(() => _items.removeWhere((item) => item.bought));
  }

  @override
  Widget build(BuildContext context) {
    final boughtCount = _items.where((i) => i.bought).length;

    return Scaffold(
      appBar: AppBar(title: const Text('買い物リスト')),
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
                      hintText: '買うものを入力',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addItem, child: const Text('追加')),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('買うものを追加しましょう'))
                : ListView.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return CheckboxListTile(
                        value: item.bought,
                        onChanged: (v) => _toggle(index, v),
                        title: Text(
                          item.name,
                          style: TextStyle(
                            decoration: item.bought
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.bought ? Colors.grey : null,
                          ),
                        ),
                        secondary: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeItem(index),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // 買えたものがあるときだけ「まとめて消す」ボタンを出す
      floatingActionButton: boughtCount == 0
          ? null
          : FloatingActionButton.extended(
              onPressed: _clearBought,
              icon: const Icon(Icons.cleaning_services),
              label: Text('買えた $boughtCount 件を消す'),
            ),
    );
  }
}
