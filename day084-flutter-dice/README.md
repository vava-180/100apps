# Day 084: サイコロ（Flutter）

1〜2個のサイコロを振って、出た目（1〜6）と**合計**を表示します。乱数の使い方と、個数に合わせて表示を並べる練習です。

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
- サイコロを1個／2個から選択
- 「振る」で 1〜6 をランダムに表示
- 2個のときは合計も表示

## 使った技術
- Flutter / Dart（`Random`・`List.generate`・`fold` による合計）
- 追加パッケージなし

## 学び・ポイント
- サイコロの目（1〜6）は `random.nextInt(6) + 1`。`nextInt(6)` は 0〜5 を返すので +1 する
- 個数分の目をまとめて作るには `List.generate(個数, ...)` が便利
- リストの合計は `fold(0, (sum, v) => sum + v)` で求められる

## 注意
- このフォルダ単体ではビルドできません（上記 `flutter create .` が必要）。

---
100日100アプリチャレンジ Day 084 / 100
