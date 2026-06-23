# TODO.md（100apps 全体計画）

100日で100個のアプリを作るチャレンジの「全体マップ」です。
- `[x]` … 作成済み（フォルダあり）
- `[ ]` … これから作る
- Day 30〜40 は今回決めた具体案。Day 41 以降は CLAUDE.md のフェーズ計画に沿った**たたき台**（後で差し替え可）。

> メモ: 外部API禁止・秘密情報を含めない・`note_object/` は触らない（RULE.md 厳守）。
> 各アプリは「1日30分・1フォルダ完結・Codex厳しめレビュー → 反映 → push」。

---

## フェーズ1：ブラウザツール（HTML / CSS / JS）  Day 1–20 … ✅ 完了

- [x] Day 001 文字数カウンター（character-counter）
- [x] Day 002 全角・半角変換（zenkaku-hankaku）
- [x] Day 003 テキスト整形（text-formatter）
- [x] Day 004 和暦カレンダー（wareki-calendar）
- [x] Day 005 議事録ジェネレーター（minutes-generator）
- [x] Day 006 表変換（table-converter）
- [x] Day 007 CSVプレビュー（csv-preview）
- [x] Day 008 見積書ジェネレーター（estimate-generator）
- [x] Day 009 QRコード生成（qr-code）
- [x] Day 010 画像リサイズ（image-resize）
- [x] Day 011 パスワード生成（password-generator）
- [x] Day 012 単位変換（unit-converter）
- [x] Day 013 カラーピッカー（color-picker）
- [x] Day 014 割り勘計算（warikan）
- [x] Day 015 ストップウォッチ／タイマー（stopwatch-timer）
- [x] Day 016 Markdownプレビュー（markdown-preview）
- [x] Day 017 ガントチャート（gantt-chart）
- [x] Day 018 ToDoリスト（todo-list）
- [x] Day 019 ポモドーロタイマー（pomodoro）
- [x] Day 020 抽選（lottery）

---

## フェーズ2：実務ツール（Python）  Day 21–40

### 作成済み Day 21–29 … ✅
- [x] Day 021 ファイル一括リネーム（batch-rename）
- [x] Day 022 複数CSV結合（csv-merge）
- [x] Day 023 PDF結合・分割（pdf-tool）
- [x] Day 024 フォルダ自動仕分け（file-organizer）
- [x] Day 025 重複ファイル検出（duplicate-finder）
- [x] Day 026 Excel NG箇所検出・一覧化（excel-ng-finder）
- [x] Day 027 テキスト一括置換（text-replace）
- [x] Day 028 フォルダ内 横断検索（folder-search）
- [x] Day 029 文字コード一括変換（encoding-convert）

### Day 30–40（今回の具体案）… ✅ 完了
- [x] Day 030 CSV集計・ピボット … 列を選んで合計／件数／平均（`csv`）
- [x] Day 031 CSV 列の抽出・絞り込み … 必要な列だけ／条件で行を絞る（`csv`）
- [x] Day 032 フォルダ容量レポート … 重いフォルダを大きい順に一覧（`pathlib`）
- [x] Day 033 フォルダ台帳CSV出力 … 名前・サイズ・更新日を棚卸しCSVに（`csv` / `pathlib`）
- [x] Day 034 2ファイル差分比較 … テキスト/CSVの「変わった行」を表示（`difflib`）
- [x] Day 035 日報／議事録テンプレ自動生成 … 今日の日付入り定型ファイルを作成（`datetime`）
- [x] Day 036 ZIP一括 圧縮／解凍 … まとめてZIP化／一括展開（`zipfile`）
- [x] Day 037 差し込みテキスト量産 … 名簿＋ひな形から文面を人数分生成（送信はしない）（`csv`）
- [x] Day 038 PDFテキスト抽出 … PDFから文字を取り出してテキスト保存（`pypdf` 既導入）
- [x] Day 039 複数Excel→1ブック集約 … 複数ブックのシートを1ファイルにまとめる（`openpyxl` 既導入）
- [x] Day 040 ファイル一括 文字数／行数統計 … フォルダ内テキストの文字数・行数を集計（標準ライブラリ）

---

## フェーズ3：Office自動化（VBA：Excel / PowerPoint / Outlook）  Day 41–65 … ※たたき台
> VBAは Office 本体が必要。実装前に対象アプリ（Excel/PPT/Outlook）と用途を再確認する。
> 並び順は Excel → PowerPoint → Outlook。

### Excel（Day 41–55）
- [x] Day 041 名簿からシート一括作成（Excel）
- [x] Day 042 複数ブック集約マクロ（Excel）
- [x] Day 043 重複行のハイライト／削除（Excel）
- [x] Day 044 セル文字の一括整形：トリム・全角半角（Excel）
- [x] Day 045 ふりがな自動付与（Excel）
- [x] Day 046 住所分割：都道府県／市区町村（Excel）
- [x] Day 047 勤怠集計マクロ（Excel）
- [ ] Day 048 請求書テンプレ一括出力（Excel）
- [ ] Day 049 グラフ一括作成（Excel）
- [ ] Day 050 印刷範囲・ページ設定の一括適用（Excel）
- [ ] Day 051 不要シート・空白行の一括削除（Excel）
- [ ] Day 052 ブック内ハイパーリンク目次（Excel）
- [ ] Day 053 CSV取り込み整形マクロ（Excel）
- [ ] Day 054 条件付き書式の一括設定（Excel）
- [ ] Day 055 カレンダー自動生成（Excel）

### PowerPoint（Day 56–61）
- [ ] Day 056 表を PowerPoint スライドへ自動転記（Excel→PPT）
- [ ] Day 057 PowerPoint 目次スライド自動生成（PPT）
- [ ] Day 058 全スライドのフォント統一（PPT）
- [ ] Day 059 画像を一括でスライド化（PPT）
- [x] Day 060 スライドの文字を一括差し替え（PPT）
- [ ] Day 061 PPTファイルのMarkdown化：スライド内容をMarkdownに書き出し（PPT）

### Outlook（Day 62–65）
- [ ] Day 062 Outlook 一斉メール下書き作成：差し込み（Outlook）
- [ ] Day 063 受信メール一覧を Excel に書き出し（Outlook）
- [ ] Day 064 添付ファイル一括保存（Outlook）
- [ ] Day 065 定型メールのテンプレ送信補助（Outlook）

---

## フェーズ4：スマホアプリ（Flutter）  Day 66–90 … ※たたき台
> Flutter 環境のセットアップが前提。最初の1本でビルド～実機/エミュ確認まで通す。

- [ ] Day 066 カウンター（Flutter入門）
- [ ] Day 067 メモ帳
- [ ] Day 068 ToDoアプリ
- [ ] Day 069 買い物リスト
- [ ] Day 070 家計簿
- [ ] Day 071 体重記録
- [ ] Day 072 習慣トラッカー
- [ ] Day 073 タイマー／ストップウォッチ
- [ ] Day 074 ポモドーロ
- [ ] Day 075 BMI計算
- [ ] Day 076 割り勘
- [ ] Day 077 チップ計算
- [ ] Day 078 単位変換
- [ ] Day 079 為替計算（レートは手入力）
- [ ] Day 080 パスワード生成
- [ ] Day 081 QRコード表示
- [ ] Day 082 カラーピッカー
- [ ] Day 083 おみくじ
- [ ] Day 084 サイコロ
- [ ] Day 085 抽選／ガチャ
- [ ] Day 086 名言表示
- [ ] Day 087 単語帳（フラッシュカード）
- [ ] Day 088 日記
- [ ] Day 089 多言語あいさつ
- [ ] Day 090 ミニ電卓

---

## フェーズ5：自由選択（用途に最適な言語）  Day 91–100 … ※たたき台

- [ ] Day 091 数当てゲーム
- [ ] Day 092 タイピング練習
- [ ] Day 093 画像加工ツール（Pillow）
- [ ] Day 094 Markdown→HTML 変換サイト
- [ ] Day 095 簡易API（FastAPI、ローカル）
- [ ] Day 096 ポートフォリオサイト
- [ ] Day 097 100apps 記録サイト（一覧自動生成）
- [ ] Day 098 ミニ機械学習デモ（ローカル）
- [ ] Day 099 まとめツール（人気アプリの合体）
- [ ] Day 100 総集編アプリ（チャレンジの集大成）

---

最終更新: 2026-06-23
