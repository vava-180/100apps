# Day 056: 表をPowerPointスライドへ自動転記（Excel VBA）

Excelで選んだ範囲を、新しいPowerPointのスライドに「図」として貼り付けるマクロです。報告資料づくりで、表をスライドに載せる手間を減らします。

## 必要なもの
- Microsoft Excel ＋ Microsoft PowerPoint（VBAが使えるデスクトップ版）

## 使い方
1. Excelでスライドに載せたい範囲を選ぶ（`sample/転記サンプル.xlsx` の表で試せます）
2. `Alt + F11` でVBE →「ファイル → ファイルのインポート」で `ExportRangeToPpt.bas` を取り込む
3. `Alt + F8` →「ExportRangeToPpt」を実行

## 機能
- 選んだ範囲を新規PowerPointの白紙スライドに「図」として貼り付け、中央に配置
- ひと続きの範囲のみ・セル数の上限（2万）でチェック
- 貼り付けはタイミングずれに備えて数回リトライ
- 失敗したら、自分が作った空のプレゼンを閉じる（PowerPoint自体は閉じない）

## 使った技術
- Excel VBA（PowerPoint自動操作 / Range.CopyPicture / Shapes.Paste）

## 学び・ポイント
- 「図」として確実に貼るには、`Range.CopyPicture(Format:=xlPicture)` で**画像としてコピー**してから貼る
  （`Copy` だけだと、環境によって表や埋め込みになることがある）
- 貼り付けは `Shapes.Paste` の**戻り値（ShapeRange）**で受け取ると、確実にその図を操作できる
- クリップボード経由は起動直後などにタイミングがずれるので、`DoEvents` ＋数回リトライが安全
- 失敗時は、自分が作った空プレゼンだけ閉じる（ユーザーが開いていたPowerPointは閉じない）

## 注意
- PowerPoint がインストールされている必要があります（ネット通信はしません・ローカル操作のみ）。
- 貼り付けは「図」です。PowerPoint側で表の文字を編集することはできません。
- マクロを含むブックは `.xlsm` 形式で保存してください。

## サンプル
- `sample/転記サンプル.xlsx` … 四半期売上の小さな表。範囲を選んで実行すると、
  新しいPowerPointのスライドに図として貼り付きます。

---
100日100アプリチャレンジ Day 056 / 100
