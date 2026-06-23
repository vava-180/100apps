// 100apps Day086: 名言表示（Flutter）
// ボタンを押すたびに、用意した名言をランダムに表示する。
// 「直前と同じものを出さない」ちょっとした工夫を学びます。

import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const QuotesApp());
}

// 名言（言葉・だれの言葉か）。
class Quote {
  final String text;
  final String author;
  const Quote(this.text, this.author);
}

// 表示する名言の一覧（オフラインで持つ・ネット通信なし）。
const List<Quote> kQuotes = [
  Quote('明日は今日より良くなる。', '作者不明'),
  Quote('千里の道も一歩から。', 'ことわざ'),
  Quote('できると思えばできる。', 'ことわざ'),
  Quote('小さな積み重ねが、大きな力になる。', '作者不明'),
  Quote('失敗は成功のもと。', 'ことわざ'),
  Quote('迷ったら、やってみる。', '作者不明'),
  Quote('続けることが、いちばんの近道。', '作者不明'),
];

class QuotesApp extends StatelessWidget {
  const QuotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '名言表示',
      theme: ThemeData(colorSchemeSeed: Colors.brown, useMaterial3: true),
      home: const QuotesPage(),
    );
  }
}

class QuotesPage extends StatefulWidget {
  const QuotesPage({super.key});

  @override
  State<QuotesPage> createState() => _QuotesPageState();
}

class _QuotesPageState extends State<QuotesPage> {
  final Random _random = Random();
  int _index = 0; // 今表示している名言の番号

  // 直前と違う名言をランダムに選ぶ（候補が2つ以上のとき）。
  void _next() {
    if (kQuotes.length <= 1) return;
    int next;
    do {
      next = _random.nextInt(kQuotes.length);
    } while (next == _index);
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final quote = kQuotes[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('今日の名言')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.format_quote, size: 48, color: Colors.brown),
            const SizedBox(height: 16),
            Text(
              quote.text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '— ${quote.author}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _next,
              icon: const Icon(Icons.refresh),
              label: const Text('次の名言'),
            ),
          ],
        ),
      ),
    );
  }
}
