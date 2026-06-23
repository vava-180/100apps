# Day 081: QRコード表示（Flutter）

入力した文字やURLを、その場で **QRコード** に変換して表示します。スマホのカメラで読み取れば、URLを開いたり文字を取り込んだりできます。

## 必要なもの
- Flutter SDK／実機・エミュレータ・Windowsデスクトップのいずれか

## 実行手順
このフォルダには `lib/main.dart` と `pubspec.yaml` だけを置いています。

```bash
flutter create .   # 足場を生成
flutter pub get    # パッケージ（qr_flutter）を取得
flutter run        # 実行
```
> `flutter create .` が `lib/main.dart`・`pubspec.yaml` を上書きしたら、本リポジトリの内容に戻してください。

## 機能
- 文字やURLを入力すると、リアルタイムでQRコードを表示
- 文字量に合わせてQRのサイズ（バージョン）を自動調整
- 空のときはQRを出さない

## 使った技術
- Flutter / Dart
- `qr_flutter` パッケージ（QR描画用・**オフライン動作／ネット通信なし**）

## 学び・ポイント
- QRコードは「誤り訂正」や「マスク処理」など中身が複雑なので、自作せず実績のあるパッケージ（`qr_flutter`）に任せるのが現実的
- `qr_flutter` は端末内で画像を描くだけで**ネット通信はしない**ため、外部APIには当たらない（本チャレンジのルール上OK）
- `QrVersions.auto` を使うと、文字量に応じてQRの細かさを自動で決めてくれる

## 注意
- 追加パッケージを使う唯一のアプリです（`flutter pub get` が必要）。
- このフォルダ単体ではビルドできません（上記 `flutter create .` が必要）。

---
100日100アプリチャレンジ Day 081 / 100
