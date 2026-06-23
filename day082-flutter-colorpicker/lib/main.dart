// 100apps Day082: カラーピッカー（Flutter）
// 赤・緑・青のスライダーを動かして色を作り、見本とカラーコード（#RRGGBB）を表示する。
// RGBの3つの値から色を組み立てる仕組みと、16進数への変換を学びます。

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ColorPickerApp());
}

class ColorPickerApp extends StatelessWidget {
  const ColorPickerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'カラーピッカー',
      theme: ThemeData(colorSchemeSeed: Colors.pink, useMaterial3: true),
      home: const ColorPickerPage(),
    );
  }
}

class ColorPickerPage extends StatefulWidget {
  const ColorPickerPage({super.key});

  @override
  State<ColorPickerPage> createState() => _ColorPickerPageState();
}

class _ColorPickerPageState extends State<ColorPickerPage> {
  double _r = 100;
  double _g = 150;
  double _b = 220;

  // 現在のRGBから色を作る。
  Color get _color =>
      Color.fromARGB(255, _r.round(), _g.round(), _b.round());

  // カラーコード（#RRGGBB）を作る。各値を2桁の16進数にそろえる。
  String get _hex {
    String two(int n) => n.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#${two(_r.round())}${two(_g.round())}${two(_b.round())}';
  }

  void _copyHex() {
    Clipboard.setData(ClipboardData(text: _hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$_hex をコピーしました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('カラーピッカー')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 作った色の見本
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(height: 12),
            // カラーコードの表示＋コピー
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SelectableText(
                  _hex,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'コピー',
                  onPressed: _copyHex,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // RGBそれぞれのスライダー
            _slider('赤 R', _r, Colors.red, (v) => setState(() => _r = v)),
            _slider('緑 G', _g, Colors.green, (v) => setState(() => _g = v)),
            _slider('青 B', _b, Colors.blue, (v) => setState(() => _b = v)),
          ],
        ),
      ),
    );
  }

  // 1色分のスライダー（0〜255）。
  Widget _slider(
    String label,
    double value,
    Color color,
    void Function(double) onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 48, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            activeColor: color,
            label: value.round().toString(),
            divisions: 255,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
