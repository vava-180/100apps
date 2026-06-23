# Day 080: パスワード生成（Flutter）

長さと「大文字・数字・記号を含めるか」を選んで、**ランダムなパスワード**を作ります。作ったパスワードはワンタップでコピーできます。

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
- 長さをスライダーで 4〜32 文字に調整
- 大文字／数字／記号を含めるかをスイッチで選択（小文字は常に使用）
- 「生成する」でランダム生成、コピーボタンでクリップボードへコピー

## 使った技術
- Flutter / Dart（`Random.secure`・`SwitchListTile`・`Slider`・`Clipboard`）
- 追加パッケージなし・ネット通信なし

## 学び・ポイント
- パスワードのように「予測されては困る乱数」は、`Random()` ではなく **`Random.secure()`**（暗号用）を使う
- 選んだ種類に応じて候補の文字（pool）を組み立て、そこから1文字ずつランダムに選ぶ
- `Clipboard.setData` でコピー。`flutter/services.dart` を import するだけで使える（追加パッケージ不要）

## 注意
- このフォルダ単体ではビルドできません（上記 `flutter create .` が必要）。

---
100日100アプリチャレンジ Day 080 / 100
