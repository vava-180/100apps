# Day 067: メモ帳（Flutter）

入力欄に書いて「追加」すると一覧に並び、不要なメモは削除できる簡単メモ帳です。**入力欄（TextField）・一覧表示（ListView）・状態更新（setState）** の練習になります。

## 必要なもの
- Flutter SDK／実機・エミュレータ・Windowsデスクトップのいずれか

## 実行手順
このフォルダには `lib/main.dart` と `pubspec.yaml` だけを置いています。

```bash
flutter create .   # 足場（android/ios/windows など）を生成
flutter run        # 実行
```
> `flutter create .` が `lib/main.dart`・`pubspec.yaml` を上書きしたら、本リポジトリの内容に戻してください。

## 機能
- メモを入力して追加（Enterでも追加）／一覧表示／1件ずつ削除
- 新しいメモを上に表示

## 使った技術
- Flutter / Dart（StatefulWidget・setState・TextEditingController・ListView.separated）
- 追加パッケージなし

## 学び・ポイント
- 入力欄の文字は `TextEditingController` で読み取る。使い終わったら `dispose()` で後片付けする（メモリリーク防止）
- 件数が変わる一覧は `ListView.separated` が便利（区切り線も簡単に入る）
- リストに対する `insert` / `removeAt` を `setState` で囲めば、画面が自動更新される

## 注意
- データはアプリ内（メモリ）に保持するため、**アプリを終了すると消えます**（保存機能は今後の拡張ポイント）。
- このフォルダ単体ではビルドできません（上記 `flutter create .` が必要）。

---
100日100アプリチャレンジ Day 067 / 100
