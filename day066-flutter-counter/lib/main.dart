// 100apps Day066: カウンター（Flutter入門）
// ＋ボタンで増やし、－ボタンで減らし、リセットで0に戻す、いちばん基本のアプリ。
// Flutterの「状態（state）を変えると画面が描き直される」仕組みを学ぶ題材です。

import 'package:flutter/material.dart';

void main() {
  runApp(const CounterApp());
}

// アプリ全体の設定（タイトル・テーマ・最初の画面）。
class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カウンター',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const CounterPage(),
    );
  }
}

// カウンターの画面。数が変わるので StatefulWidget（状態を持つ部品）にする。
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0; // 今の数

  // setState で値を変えると、画面が自動で描き直される。
  void _increment() => setState(() => _count++);
  void _decrement() => setState(() => _count--);
  void _reset() => setState(() => _count = 0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('カウンター')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('今の数', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '$_count',
              style: theme.textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // ＋ と － を横並びに置く
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.tonal(
                  onPressed: _decrement,
                  child: const Text('－ 減らす'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _increment,
                  child: const Text('＋ 増やす'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _reset,
              child: const Text('リセット'),
            ),
          ],
        ),
      ),
    );
  }
}
