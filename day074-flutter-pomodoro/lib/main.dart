// 100apps Day074: ポモドーロタイマー（Flutter）
// 「25分作業 → 5分休憩」を繰り返す集中タイマー。0になると自動で作業/休憩が切り替わる。
// 1秒ごとのカウントダウンと、状態（作業中/休憩中）の切り替えを学びます。

import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const PomodoroApp());
}

class PomodoroApp extends StatelessWidget {
  const PomodoroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ポモドーロ',
      theme: ThemeData(colorSchemeSeed: Colors.red, useMaterial3: true),
      home: const PomodoroPage(),
    );
  }
}

class PomodoroPage extends StatefulWidget {
  const PomodoroPage({super.key});

  @override
  State<PomodoroPage> createState() => _PomodoroPageState();
}

class _PomodoroPageState extends State<PomodoroPage> {
  static const int workSeconds = 25 * 60; // 作業25分
  static const int breakSeconds = 5 * 60; // 休憩5分

  Timer? _timer;
  bool _isWork = true; // true=作業中, false=休憩中
  int _remaining = workSeconds; // 残り秒
  int _doneCount = 0; // 終わった作業の回数

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isRunning => _timer != null;

  void _start() {
    if (_isRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        // 残り1秒以下なら、ちょうど0になるこのtickでフェーズを切り替える
        // （0表示のまま1秒余分に待たないようにする）。
        if (_remaining <= 1) {
          _switchPhase(); // 作業/休憩を入れ替える
        } else {
          _remaining -= 1;
        }
      });
    });
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  // 今のタイマーを初期状態（作業25分）に戻す。
  void _reset() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _isWork = true;
      _remaining = workSeconds;
    });
  }

  // 作業→休憩、休憩→作業へ切り替える。
  void _switchPhase() {
    if (_isWork) {
      _doneCount += 1; // 作業を1回やり切った
      _isWork = false;
      _remaining = breakSeconds;
    } else {
      _isWork = true;
      _remaining = workSeconds;
    }
  }

  String _format(int totalSeconds) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(totalSeconds ~/ 60)}:${two(totalSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _isWork ? Colors.red : Colors.green;
    // 残り時間の割合（進捗リング用）。1.0→0.0へ減っていく。
    final total = _isWork ? workSeconds : breakSeconds;
    final progress = total == 0 ? 0.0 : _remaining / total;

    return Scaffold(
      appBar: AppBar(title: const Text('ポモドーロ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 作業中／休憩中の表示
            Text(
              _isWork ? '作業中' : '休憩中',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            // 残り時間（円グラフ風のリングの中に表示）
            SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.15),
                    ),
                  ),
                  Text(
                    _format(_remaining),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('完了した作業：$_doneCount 回', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            // 操作ボタン
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _isRunning ? _pause : _start,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                  label: Text(_isRunning ? '一時停止' : 'スタート'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.refresh),
                  label: const Text('リセット'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
