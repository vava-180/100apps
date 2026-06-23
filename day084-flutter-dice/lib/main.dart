// 100apps Day084: サイコロ（Flutter）
// 1〜2個のサイコロを振って、出た目（1〜6）と合計を表示する。
// 乱数の使い方と、個数に合わせて目の表示を並べる方法を学びます。

import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const DiceApp());
}

class DiceApp extends StatelessWidget {
  const DiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'サイコロ',
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const DicePage(),
    );
  }
}

class DicePage extends StatefulWidget {
  const DicePage({super.key});

  @override
  State<DicePage> createState() => _DicePageState();
}

class _DicePageState extends State<DicePage> {
  final Random _random = Random();
  int _count = 1; // サイコロの個数（1〜2）
  List<int> _values = [1]; // 出た目

  // サイコロを個数分振る。
  void _roll() {
    setState(() {
      _values = List.generate(_count, (_) => _random.nextInt(6) + 1);
    });
  }

  // 個数を変えたら、目の数も合わせて振り直す。
  void _setCount(int count) {
    setState(() {
      _count = count;
      _values = List.generate(_count, (_) => _random.nextInt(6) + 1);
    });
  }

  int get _total => _values.fold(0, (sum, v) => sum + v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('サイコロ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 個数の選択
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('1個')),
                ButtonSegment(value: 2, label: Text('2個')),
              ],
              selected: {_count},
              onSelectionChanged: (s) => _setCount(s.first),
            ),
            const SizedBox(height: 32),
            // 出た目を横に並べる
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final v in _values) _DiceFace(value: v),
              ],
            ),
            const SizedBox(height: 24),
            if (_values.length >= 2)
              Text(
                '合計：$_total',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _roll,
              icon: const Icon(Icons.casino),
              label: const Text('振る'),
            ),
          ],
        ),
      ),
    );
  }
}

// サイコロ1個の面（目を点で表示する）。
class _DiceFace extends StatelessWidget {
  final int value;
  const _DiceFace({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black26, width: 2),
      ),
      child: Center(
        child: Text(
          '$value',
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
