// 100apps Day073: ストップウォッチ（Flutter）
// スタート・ストップ・リセットができるストップウォッチ。ラップ（途中計測）付き。
// Timer.periodic で時間を進める方法と、後始末（dispose でタイマー停止）を学びます。

import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const StopwatchApp());
}

class StopwatchApp extends StatelessWidget {
  const StopwatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ストップウォッチ',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const StopwatchPage(),
    );
  }
}

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  // 経過時間の計測は Dart 標準の Stopwatch に任せ、画面更新だけ Timer で行う。
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<Duration> _laps = [];

  @override
  void dispose() {
    // 画面が消えるときにタイマーを必ず止める（止め忘れ防止）。
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_stopwatch.isRunning) return;
    _stopwatch.start();
    // 30ミリ秒ごとに画面を再描画して時間を進める。
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      setState(() {});
    });
  }

  void _stop() {
    if (!_stopwatch.isRunning) return;
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _reset() {
    _stopwatch.stop();
    _stopwatch.reset();
    _timer?.cancel();
    _timer = null;
    setState(() => _laps.clear());
  }

  // ラップ（その瞬間の経過時間）を記録する。
  void _lap() {
    if (!_stopwatch.isRunning) return;
    setState(() => _laps.insert(0, _stopwatch.elapsed));
  }

  // Duration を「分:秒.百分の1秒」の形に整える。
  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final minutes = two(d.inMinutes);
    final seconds = two(d.inSeconds % 60);
    final centi = two((d.inMilliseconds % 1000) ~/ 10);
    return '$minutes:$seconds.$centi';
  }

  @override
  Widget build(BuildContext context) {
    final running = _stopwatch.isRunning;

    return Scaffold(
      appBar: AppBar(title: const Text('ストップウォッチ')),
      body: Column(
        children: [
          const SizedBox(height: 32),
          // 経過時間の表示
          Center(
            child: Text(
              _format(_stopwatch.elapsed),
              style: const TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // 操作ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: running ? _stop : _start,
                icon: Icon(running ? Icons.pause : Icons.play_arrow),
                label: Text(running ? 'ストップ' : 'スタート'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: running ? _lap : _reset,
                icon: Icon(running ? Icons.flag : Icons.refresh),
                label: Text(running ? 'ラップ' : 'リセット'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          // ラップの一覧
          Expanded(
            child: _laps.isEmpty
                ? const Center(child: Text('ラップはまだありません'))
                : ListView.separated(
                    itemCount: _laps.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      // 新しいラップを上に入れているので、番号は逆算する。
                      final lapNo = _laps.length - index;
                      return ListTile(
                        leading: Text('ラップ $lapNo'),
                        trailing: Text(
                          _format(_laps[index]),
                          style: const TextStyle(
                            fontSize: 18,
                            fontFeatures: [FontFeature.tabularFigures()],
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
