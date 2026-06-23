// 100apps Day081: QRコード表示（Flutter）
// 入力した文字やURLを、その場でQRコードに変換して表示する。
// ※QRの生成は qr_flutter パッケージを使用（オフラインで動作・ネット通信なし）。

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

void main() {
  runApp(const QrApp());
}

class QrApp extends StatelessWidget {
  const QrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRコード表示',
      theme: ThemeData(colorSchemeSeed: Colors.black, useMaterial3: true),
      home: const QrPage(),
    );
  }
}

class QrPage extends StatefulWidget {
  const QrPage({super.key});

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  final TextEditingController _controller = TextEditingController();
  String _data = ''; // QRにする文字（空のときはQRを出さない）

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 入力のたびに、QRにする文字を更新する。
  void _update(String text) {
    setState(() => _data = text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QRコード表示')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: '文字やURLを入力',
                hintText: '例: https://example.com',
                border: OutlineInputBorder(),
              ),
              onChanged: _update,
            ),
            const SizedBox(height: 24),
            // QRコードの表示（入力があるときだけ）
            Expanded(
              child: Center(
                child: _data.isEmpty
                    ? const Text(
                        '入力するとQRコードが表示されます',
                        style: TextStyle(color: Colors.grey),
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white, // QRは白地が読み取りやすい
                        child: QrImageView(
                          data: _data,
                          version: QrVersions.auto, // 文字量に合わせて自動調整
                          size: 240,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
