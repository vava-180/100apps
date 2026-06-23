// 100apps Day080: パスワード生成（Flutter）
// 長さと「大文字・数字・記号を含めるか」を選んで、ランダムなパスワードを作る。
// 乱数（Random.secure）と、選んだ条件から文字の候補を組み立てる方法を学びます。

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const PasswordApp());
}

class PasswordApp extends StatelessWidget {
  const PasswordApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'パスワード生成',
      theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
      home: const PasswordPage(),
    );
  }
}

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
  // 文字の種類ごとの候補。
  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '!@#\$%&*?-_';

  // 予測されにくい乱数（暗号用）。
  final Random _random = Random.secure();

  double _length = 12; // パスワードの長さ
  bool _useUpper = true;
  bool _useDigits = true;
  bool _useSymbols = false;
  String _password = '';

  // 選んだ条件からパスワードを作る。
  void _generate() {
    // 小文字は必ず使い、選ばれた種類を足していく。
    var pool = _lower;
    if (_useUpper) pool += _upper;
    if (_useDigits) pool += _digits;
    if (_useSymbols) pool += _symbols;

    final length = _length.round();
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      // 候補から1文字をランダムに選ぶ。
      buffer.write(pool[_random.nextInt(pool.length)]);
    }
    setState(() => _password = buffer.toString());
  }

  // 生成したパスワードをクリップボードへコピーする。
  void _copy() {
    if (_password.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _password));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('コピーしました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('パスワード生成')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 生成結果の表示＋コピー
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _password.isEmpty ? '（ここに表示されます）' : _password,
                        style: TextStyle(
                          fontSize: 20,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: _password.isEmpty ? Colors.grey : null,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'コピー',
                      onPressed: _password.isEmpty ? null : _copy,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 長さスライダー
            Text('長さ：${_length.round()} 文字',
                style: const TextStyle(fontSize: 16)),
            Slider(
              value: _length,
              min: 4,
              max: 32,
              divisions: 28,
              label: '${_length.round()}',
              onChanged: (v) => setState(() => _length = v),
            ),
            // 含める文字の種類
            SwitchListTile(
              title: const Text('大文字（A-Z）を含める'),
              value: _useUpper,
              onChanged: (v) => setState(() => _useUpper = v),
            ),
            SwitchListTile(
              title: const Text('数字（0-9）を含める'),
              value: _useDigits,
              onChanged: (v) => setState(() => _useDigits = v),
            ),
            SwitchListTile(
              title: const Text('記号（!@#…）を含める'),
              value: _useSymbols,
              onChanged: (v) => setState(() => _useSymbols = v),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _generate,
              icon: const Icon(Icons.casino),
              label: const Text('生成する'),
            ),
          ],
        ),
      ),
    );
  }
}
