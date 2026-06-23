// 100apps Day089: 多言語あいさつ（Flutter）
// 国（言語）を選ぶと、その言語の「こんにちは」と読み方を大きく表示する。
// 「選んだ項目に対応するデータを取り出す」基本（リスト＋選択状態）を学びます。

import 'package:flutter/material.dart';

void main() {
  runApp(const GreetingApp());
}

// あいさつ1件（国旗・言語名・あいさつ・読み方）。
class Greeting {
  final String flag;
  final String language;
  final String hello;
  final String reading;
  const Greeting(this.flag, this.language, this.hello, this.reading);
}

// あいさつの一覧（オフラインで持つ・ネット通信なし）。
const List<Greeting> kGreetings = [
  Greeting('🇯🇵', '日本語', 'こんにちは', 'konnichiwa'),
  Greeting('🇺🇸', '英語', 'Hello', 'ハロー'),
  Greeting('🇨🇳', '中国語', '你好', 'ニーハオ'),
  Greeting('🇰🇷', '韓国語', '안녕하세요', 'アンニョンハセヨ'),
  Greeting('🇫🇷', 'フランス語', 'Bonjour', 'ボンジュール'),
  Greeting('🇪🇸', 'スペイン語', 'Hola', 'オラ'),
  Greeting('🇩🇪', 'ドイツ語', 'Hallo', 'ハロー'),
  Greeting('🇮🇹', 'イタリア語', 'Ciao', 'チャオ'),
];

class GreetingApp extends StatelessWidget {
  const GreetingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '多言語あいさつ',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const GreetingPage(),
    );
  }
}

class GreetingPage extends StatefulWidget {
  const GreetingPage({super.key});

  @override
  State<GreetingPage> createState() => _GreetingPageState();
}

class _GreetingPageState extends State<GreetingPage> {
  int _index = 0; // 選んでいる言語の番号

  @override
  Widget build(BuildContext context) {
    final g = kGreetings[_index];

    return Scaffold(
      appBar: AppBar(title: const Text('多言語あいさつ')),
      body: Column(
        children: [
          // 選んだ言語のあいさつを大きく表示
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(g.flag, style: const TextStyle(fontSize: 72)),
                  const SizedBox(height: 8),
                  Text(
                    g.hello,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '（${g.reading}）',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(g.language, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // 言語を選ぶリスト（横スクロール）
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              itemCount: kGreetings.length,
              itemBuilder: (context, i) {
                final selected = i == _index;
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected ? Colors.indigo : Colors.black12,
                        width: selected ? 2 : 1,
                      ),
                      color: selected
                          ? Colors.indigo.withValues(alpha: 0.1)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(kGreetings[i].flag,
                            style: const TextStyle(fontSize: 28)),
                        const SizedBox(height: 4),
                        Text(
                          kGreetings[i].language,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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
