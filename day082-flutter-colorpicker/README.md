# Day 082: カラーピッカー（Flutter）

赤・緑・青のスライダーを動かして色を作り、**見本**と**カラーコード（#RRGGBB）**を表示します。コードはワンタップでコピーできます。

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
- 赤(R)・緑(G)・青(B) を 0〜255 のスライダーで調整
- 作った色を大きな見本で表示
- カラーコード（#RRGGBB）を表示／コピー

## 使った技術
- Flutter / Dart（`Color.fromARGB`・`toRadixString(16)`・`Clipboard`）
- 追加パッケージなし

## 学び・ポイント
- 画面の色は「赤・緑・青の3つの強さ（各0〜255）」の組み合わせでできている（光の三原色）
- 16進数への変換は `toRadixString(16)`。1桁になることがあるので `padLeft(2, '0')` で必ず2桁にそろえる
- スライダーの値は `double`。色に使うときは `round()` で整数にする

## 注意
- このフォルダ単体ではビルドできません（上記 `flutter create .` が必要）。

---
100日100アプリチャレンジ Day 082 / 100
