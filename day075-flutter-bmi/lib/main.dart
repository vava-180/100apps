// 100apps Day075: BMI計算（Flutter）
// 身長（cm）と体重（kg）からBMIを計算し、判定（低体重〜肥満）を表示する。
// 計算式と入力チェック、結果の色分け表示を学びます。

import 'package:flutter/material.dart';

void main() {
  runApp(const BmiApp());
}

class BmiApp extends StatelessWidget {
  const BmiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMI計算',
      theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true),
      home: const BmiPage(),
    );
  }
}

class BmiPage extends StatefulWidget {
  const BmiPage({super.key});

  @override
  State<BmiPage> createState() => _BmiPageState();
}

class _BmiPageState extends State<BmiPage> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  double? _bmi; // 計算結果（未計算は null）

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // 入力を読み取ってBMIを計算する。
  void _calc() {
    final heightCm = double.tryParse(_heightController.text.trim());
    final weightKg = double.tryParse(_weightController.text.trim());
    if (heightCm == null ||
        weightKg == null ||
        heightCm <= 0 ||
        weightKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('身長と体重を正しい数字で入力してください')),
      );
      return;
    }
    // BMI = 体重kg ÷ (身長m × 身長m)
    final heightM = heightCm / 100;
    setState(() => _bmi = weightKg / (heightM * heightM));
  }

  // BMIの値から日本肥満学会の区分で判定する。
  String get _category {
    final bmi = _bmi;
    if (bmi == null) return '';
    if (bmi < 18.5) return '低体重';
    if (bmi < 25) return '普通体重';
    if (bmi < 30) return '肥満（1度）';
    if (bmi < 35) return '肥満（2度）';
    if (bmi < 40) return '肥満（3度）';
    return '肥満（4度）';
  }

  Color get _categoryColor {
    final bmi = _bmi;
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final bmi = _bmi;

    return Scaffold(
      appBar: AppBar(title: const Text('BMI計算')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '身長（cm）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '体重（kg）',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _calc(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _calc,
                child: const Text('計算する'),
              ),
            ),
            const SizedBox(height: 24),
            // 結果カード
            if (bmi != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text('あなたのBMI', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        bmi.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          color: _categoryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _category,
                        style: TextStyle(
                          fontSize: 20,
                          color: _categoryColor,
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
}
