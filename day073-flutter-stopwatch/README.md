# Day 073: ストップウォッチ（Flutter）

スタート・ストップ・リセットができるストップウォッチです。**ラップ（途中計測）**も記録できます。時間を進める `Timer` と、その後始末（`dispose`）を学べます。

## 必要なもの
- Flutter SDK／実機・エミュレータ・Windowsデスクトップのいずれか

## 実行手順
このフォルダには `lib/main.dart` と `pubspec.yaml` だけを置いています。

```bash
flutter create .   # 足場を生成
flutter run        # 実行
```
> `flutter create .` が `lib/main.dart`・`pubspec.yaml` を上書きしたら、本リポジトリの内容に戻してください。

## 機能
- スタート／ストップ／リセット
- 動作中は「ラップ」ボタンで途中経過を記録（新しい順に一覧表示）
- 「分:秒.百分の1秒」で表示

## 使った技術
- Flutter / Dart（標準の `Stopwatch`・`Timer.periodic`・`Duration`）
- 追加パッケージなし

## 学び・ポイント
- 時間そのものは Dart 標準の `Stopwatch` に任せ、`Timer` は「画面を定期的に描き直す」役にすると正確かつシンプル
- **`Timer` は使い終わったら必ず `cancel()`**。画面が消えるときに `dispose` で止めないと裏で動き続けてしまう
- 数字がガタつかないよう `FontFeature.tabularFigures()`（等幅数字）を使うと読みやすい

## 注意
- このフォルダ単体ではビルドできません（上記 `flutter create .` が必要）。

---
100日100アプリチャレンジ Day 073 / 100
