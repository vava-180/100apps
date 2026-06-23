// 100apps Day090: ミニ電卓（Flutter）
// 四則演算（＋ − × ÷）ができる簡単な電卓。クリア・小数点・ゼロ除算対策つき。
// 「今の入力」「前の数」「待っている計算」を状態として持つ電卓の作りを学びます。

import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ミニ電卓',
      theme: ThemeData(colorSchemeSeed: Colors.blueGrey, useMaterial3: true),
      home: const CalculatorPage(),
    );
  }
}

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display = '0'; // 画面に出ている数
  double? _stored; // 1つ前の数（計算待ち）
  String? _pendingOp; // 待っている演算子（＋ − × ÷）
  bool _startNew = true; // 次の数字入力で表示をリセットするか
  bool _isError = false; // ゼロ除算などのエラー中か
  // ＝の連打用：直前の「演算子」と「右側の数」を覚えておく（例: 3+2= の後の＝で +2 を繰り返す）。
  double? _repeatOperand;
  String? _repeatOp;

  // 数字を押したとき。
  void _inputDigit(String digit) {
    setState(() {
      if (_isError) _clearAll(); // エラー中はまずリセット
      if (_startNew || _display == '0') {
        _display = digit;
        _startNew = false;
      } else {
        _display += digit;
      }
    });
  }

  // 小数点を押したとき（すでに点があれば何もしない）。
  void _inputDot() {
    setState(() {
      if (_isError) _clearAll();
      if (_startNew) {
        _display = '0.';
        _startNew = false;
      } else if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  // 演算子（＋ − × ÷）を押したとき。
  void _setOperator(String op) {
    setState(() {
      if (_isError) return;
      final current = double.parse(_display);
      if (_stored != null && _pendingOp != null && !_startNew) {
        // 連続入力（例: 1 + 2 + …）のときは、ここまでを先に計算する
        final result = _calculate(_stored!, current, _pendingOp!);
        if (result == null || !result.isFinite) {
          _showError();
          return;
        }
        _stored = result;
        _display = _format(result);
      } else {
        _stored = current;
      }
      _pendingOp = op;
      _startNew = true; // 次の数字入力で表示を切り替える
      // 新しい演算を始めたので、＝連打用の記録はいったん消す
      _repeatOp = null;
      _repeatOperand = null;
    });
  }

  // ＝を押したとき。
  void _equals() {
    setState(() {
      if (_isError) return;
      // 待っている計算も、＝連打用の記録も無ければ何もしない
      if (_pendingOp == null && _repeatOp == null) return;

      final current = double.parse(_display);
      // 通常は「前の数 ＜演算子＞ 今の数」。＝の連打中は「今の数 ＜直前の演算子＞ 直前の右の数」。
      final op = _pendingOp ?? _repeatOp!;
      final lhs = _pendingOp != null ? _stored! : current;
      final rhs = _pendingOp != null ? current : _repeatOperand!;

      final result = _calculate(lhs, rhs, op);
      if (result == null || !result.isFinite) {
        _showError();
        return;
      }
      _display = _format(result);
      // 次の＝で同じ演算（＜op＞ rhs）を繰り返せるよう記録する
      _repeatOp = op;
      _repeatOperand = rhs;
      _stored = null;
      _pendingOp = null;
      _startNew = true;
    });
  }

  // 実際の計算。割る数が0のときは null を返す（＝エラー）。
  double? _calculate(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '−':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) return null;
        return a / b;
    }
    return null;
  }

  // すべてリセット（C）。
  void _clearAll() {
    _display = '0';
    _stored = null;
    _pendingOp = null;
    _startNew = true;
    _isError = false;
    _repeatOp = null;
    _repeatOperand = null;
  }

  void _showError() {
    _display = 'エラー';
    _stored = null;
    _pendingOp = null;
    _startNew = true;
    _isError = true;
  }

  // 計算結果の表示を整える（整数なら小数点を付けない）。
  String _format(double value) {
    if (!value.isFinite) return 'エラー'; // 念のため（無限大・非数）
    // 整数（小数部が無い）なら、小数点なしの整数として表示する。
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ミニ電卓')),
      body: Column(
        children: [
          // 表示エリア
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            alignment: Alignment.centerRight,
            child: Text(
              _display,
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          // ボタン群
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buttonRow(['C', '÷']),
                  _buttonRow(['7', '8', '9', '×']),
                  _buttonRow(['4', '5', '6', '−']),
                  _buttonRow(['1', '2', '3', '+']),
                  _buttonRow(['0', '.', '＝']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ボタンを1行ぶん並べる。
  Widget _buttonRow(List<String> labels) {
    return Expanded(
      child: Row(
        children: [
          for (final label in labels) _button(label),
        ],
      ),
    );
  }

  // ボタン1個。種類によって色と動きを変える。
  Widget _button(String label) {
    final isOperator = ['÷', '×', '−', '+', '＝'].contains(label);
    final isClear = label == 'C';

    Color? bg;
    Color? fg;
    if (isClear) {
      bg = Colors.red.shade100;
      fg = Colors.red.shade900;
    } else if (isOperator) {
      bg = Colors.blueGrey.shade100;
      fg = Colors.blueGrey.shade900;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          onPressed: () => _onPressed(label),
          child: Text(label, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }

  // 押されたボタンに応じて処理を振り分ける。
  void _onPressed(String label) {
    if (label == 'C') {
      setState(_clearAll);
    } else if (label == '＝') {
      _equals();
    } else if (label == '.') {
      _inputDot();
    } else if (['÷', '×', '−', '+'].contains(label)) {
      _setOperator(label);
    } else {
      _inputDigit(label); // 数字
    }
  }
}
