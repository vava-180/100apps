// 100apps Day083: おみくじ（Flutter）
// ボタンを押すと、運勢（大吉〜凶）とひとことメッセージをランダムに表示する。
// 候補リストから1つをランダムに選ぶ基本と、結果の色分け表示を学びます。

import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const OmikujiApp());
}

// おみくじの1つ（運勢名・色・ひとこと）。
class Fortune {
  final String name;
  final Color color;
  final String message;
  const Fortune(this.name, this.color, this.message);
}

// 運勢の候補（上から出やすい順ではなく、すべて同じ確率で選ぶ）。
const List<Fortune> kFortunes = [
  Fortune('大吉', Colors.red, 'すべて順調。思い切って行動しよう！'),
  Fortune('中吉', Colors.orange, '良い流れ。コツコツ続けると吉。'),
  Fortune('小吉', Colors.amber, '小さな幸せがある一日。'),
  Fortune('吉', Colors.green, '落ち着いて進めば大丈夫。'),
  Fortune('末吉', Colors.teal, 'これから運が上向くきざし。'),
  Fortune('凶', Colors.blueGrey, '慎重に。無理せず休む勇気も大事。'),
];

class OmikujiApp extends StatelessWidget {
  const OmikujiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'おみくじ',
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const OmikujiPage(),
    );
  }
}

class OmikujiPage extends StatefulWidget {
  const OmikujiPage({super.key});

  @override
  State<OmikujiPage> createState() => _OmikujiPageState();
}

class _OmikujiPageState extends State<OmikujiPage> {
  final Random _random = Random();
  Fortune? _result; // まだ引いていないときは null

  // 候補からランダムに1つ選ぶ。
  void _draw() {
    setState(() => _result = kFortunes[_random.nextInt(kFortunes.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('おみくじ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (result == null)
              const Text(
                'ボタンを押して運勢を占おう',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              )
            else ...[
              Text(
                result.name,
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: result.color,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: _draw,
              icon: const Icon(Icons.auto_awesome),
              label: Text(result == null ? 'おみくじを引く' : 'もう一度引く'),
            ),
          ],
        ),
      ),
    );
  }
}
