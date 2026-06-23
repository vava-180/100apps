# Day 066: カウンター（Flutter入門）

Flutterフェーズ（Day 66〜90）の1本目。＋で増やし、－で減らし、リセットで0に戻す、いちばん基本のアプリです。Flutterの**「状態（state）を変えると画面が描き直される」**仕組みを学びます。

## 必要なもの
- Flutter SDK（`flutter --version` で確認）
- エディタ（VS Code など）／実機・エミュレータ・Windowsデスクトップのいずれか

## 実行手順
このフォルダには `lib/main.dart` と `pubspec.yaml` だけを置いています（プラットフォーム用の足場ファイルは含めていません）。次の手順で動かせます。

```bash
# 1) 足場（android/ios/windows など）を生成する
flutter create .

# 2) このフォルダの lib/main.dart と pubspec.yaml はそのまま使う
#    （flutter create で上書きされた場合は、本リポジトリの内容に戻す）

# 3) 実行（接続中の端末・エミュレータ・Windowsなどで起動）
flutter run
```

> メモ: `flutter create .` は `lib/main.dart` と `pubspec.yaml` を上書きすることがあります。上書きされたら、このリポジトリのファイルで置き換えてから `flutter run` してください。

## 機能
- ＋で +1、－で −1、リセットで 0
- Material 3 のテーマ（indigo）

## 使った技術
- Flutter / Dart（StatefulWidget・setState）
- 追加パッケージなし（標準のMaterialのみ）

## 学び・ポイント
- 画面が変化するUIは `StatefulWidget`。値を変えるときは **`setState(() { ... })`** で囲むと、Flutterが自動で画面を描き直す
- `MaterialApp` → `Scaffold`（AppBar＋body）→ `Column`/`Row` という入れ子で画面を組み立てる
- ボタンは `FilledButton`（強調）・`FilledButton.tonal`（控えめ）・`TextButton`（最も控えめ）で役割を分けられる

## 注意
- このフォルダ単体ではビルドできません。上記の `flutter create .` で足場を作ってください。

---
100日100アプリチャレンジ Day 066 / 100
