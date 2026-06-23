// 100apps Day085: 抽選・ガチャ（Flutter）
// ボタンを引くと、レア度ごとの「当たりやすさ（重み）」に従って結果が出るガチャ。
// 「重み付き抽選」（出やすさに差をつけた抽選）の考え方を学びます。

import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const GachaApp());
}

// ガチャの景品（レア度名・色・出やすさの重み）。
class Prize {
  final String name;
  final Color color;
  final int weight; // 大きいほど出やすい
  const Prize(this.name, this.color, this.weight);
}

// 重みの合計は 1+5+14+30+50 = 100。重み＝そのまま当たる％になる。
// レアほど重みを小さく（出にくく）してある。
const List<Prize> kPrizes = [
  Prize('★5 ウルトラレア', Colors.amber, 1),
  Prize('★4 スーパーレア', Colors.purple, 5),
  Prize('★3 レア', Colors.blue, 14),
  Prize('★2 アンコモン', Colors.teal, 30),
  Prize('★1 ノーマル', Colors.blueGrey, 50),
];

class GachaApp extends StatelessWidget {
  const GachaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '抽選・ガチャ',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
      home: const GachaPage(),
    );
  }
}

class GachaPage extends StatefulWidget {
  const GachaPage({super.key});

  @override
  State<GachaPage> createState() => _GachaPageState();
}

class _GachaPageState extends State<GachaPage> {
  final Random _random = Random();
  Prize? _result; // 引く前は null
  int _count = 0; // 引いた回数

  // 重み付き抽選：合計の重みの中から1点を選び、どの景品の範囲かを調べる。
  Prize _drawPrize() {
    final totalWeight = kPrizes.fold(0, (sum, p) => sum + p.weight);
    var point = _random.nextInt(totalWeight); // 0〜(合計-1)
    for (final prize in kPrizes) {
      if (point < prize.weight) return prize;
      point -= prize.weight;
    }
    return kPrizes.last; // 念のため（通常ここには来ない）
  }

  void _draw() {
    setState(() {
      _result = _drawPrize();
      _count += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('抽選・ガチャ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (result == null)
              const Text(
                'ボタンを押してガチャを引こう',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: result.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: result.color, width: 2),
                ),
                child: Text(
                  result.name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: result.color,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text('引いた回数：$_count 回',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _draw,
              icon: const Icon(Icons.redeem),
              label: const Text('ガチャを引く'),
            ),
            const SizedBox(height: 32),
            // 確率の説明
            const Text('出やすさ', style: TextStyle(fontWeight: FontWeight.bold)),
            for (final p in kPrizes)
              Text('${p.name}：${p.weight}%',
                  style: TextStyle(color: p.color)),
          ],
        ),
      ),
    );
  }
}
