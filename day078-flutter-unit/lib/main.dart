// 100apps Day078: 単位変換（長さ）（Flutter）
// 「mm/cm/m/km」をドロップダウンで選び、入力値を変換する。
// 「基準の単位（m）に一度そろえてから変換する」という考え方を学びます。

import 'package:flutter/material.dart';

void main() {
  runApp(const UnitApp());
}

// 単位の名前と「1単位＝何メートルか（係数）」。
class Unit {
  final String name;
  final double toMeter; // 1<単位> = toMeter メートル
  const Unit(this.name, this.toMeter);
}

const List<Unit> kUnits = [
  Unit('mm', 0.001),
  Unit('cm', 0.01),
  Unit('m', 1),
  Unit('km', 1000),
];

class UnitApp extends StatelessWidget {
  const UnitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '単位変換',
      theme: ThemeData(colorSchemeSeed: Colors.cyan, useMaterial3: true),
      home: const UnitPage(),
    );
  }
}

class UnitPage extends StatefulWidget {
  const UnitPage({super.key});

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  final TextEditingController _controller = TextEditingController();
  Unit _from = kUnits[1]; // cm
  Unit _to = kUnits[2]; // m

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 変換結果（入力が数字でなければ null）。
  double? get _result {
    final value = double.tryParse(_controller.text.trim());
    if (value == null) return null;
    // 一度メートルにそろえてから、変換先の単位に直す。
    final meters = value * _from.toMeter;
    return meters / _to.toMeter;
  }

  // from と to を入れ替える。
  void _swap() {
    setState(() {
      final tmp = _from;
      _from = _to;
      _to = tmp;
    });
  }

  // 余計な小数の0を消して見やすくする（例: 1.50 → 1.5）。
  String _trim(double v) {
    var s = v.toStringAsFixed(6);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;

    return Scaffold(
      appBar: AppBar(title: const Text('単位変換（長さ）')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '変換する値',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // 変換元 → 変換先のドロップダウン
            Row(
              children: [
                Expanded(child: _dropdown(_from, (u) => _from = u)),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: _swap,
                  tooltip: '入れ替え',
                ),
                Expanded(child: _dropdown(_to, (u) => _to = u)),
              ],
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('変換結果', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      result == null
                          ? '—'
                          : '${_trim(result)} ${_to.name}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 単位を選ぶドロップダウン。選んだら setState で再描画。
  Widget _dropdown(Unit current, void Function(Unit) onPick) {
    return DropdownButtonFormField<Unit>(
      initialValue: current,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: kUnits
          .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
          .toList(),
      onChanged: (u) {
        if (u != null) setState(() => onPick(u));
      },
    );
  }
}
