# 100日100アプリチャレンジ 🚀

IT初心者が、100日間で100個のアプリを作る記録です。
小さくても毎日1個ずつ完成させて、GitHubで公開・noteで発信していきます。

## 📌 ルール
- 1日1アプリ、必ず「完成」させる（小さくてOK）
- ソースコードはGitHubで公開
- 進捗・学びはnoteに記録
- 外部APIを使うものは事前に検討してから採用する

## 🔁 ワークフロー
1. 仕様メモ（何をする／完成の条件を1〜2行）
2. Claude Code で構想＆実装
3. Codex でチェック（動くか・読みやすいか・エラー処理）
4. 修正（あれば）
5. README＋スクショ＋公開

## 📂 構成
各アプリは `dayXXX-アプリ名/` フォルダに入っています。
それぞれのフォルダに、コードと小さなREADMEがあります。

## 📊 進捗一覧

凡例：✅ 完成 / 🔨 制作中 / ⬜ 未着手

### フェーズ1：ブラウザツール（Day 1–20）― HTML / CSS / JavaScript
| Day | アプリ | 状態 | デモ |
|----:|--------|:----:|:----:|
| 001 | 文字数カウンター | ✅ | [開く](day001-character-counter/index.html) |
| 002 | 全角↔半角変換 | ✅ | [開く](day002-zenkaku-hankaku/index.html) |
| 003 | テキスト整形ツール | ✅ | [開く](day003-text-formatter/index.html) |
| 004 | 西暦↔和暦＆営業日計算 | ✅ | [開く](day004-wareki-calendar/index.html) |
| 005 | 議事録ジェネレータ | ✅ | [開く](day005-minutes-generator/index.html) |
| 006 | 表→Markdown / HTML変換 | ✅ | [開く](day006-table-converter/index.html) |
| 007 | CSV→表プレビュー＆印刷 | ✅ | [開く](day007-csv-preview/index.html) |
| 008 | 簡易見積書ジェネレータ | ✅ | [開く](day008-estimate-generator/index.html) |
| 009 | QRコード生成 | ✅ | [開く](day009-qr-code/index.html) |
| 010 | 画像リサイズ・圧縮 | ✅ | [開く](day010-image-resize/index.html) |
| 011 | パスワード生成ツール | ✅ | [開く](day011-password-generator/index.html) |
| 012 | 単位換算ツール | ✅ | [開く](day012-unit-converter/index.html) |
| 013 | カラーピッカー＆パレット | ✅ | [開く](day013-color-picker/index.html) |
| 014 | 割り勘計算機 | ✅ | [開く](day014-warikan/index.html) |
| 015 | ストップウォッチ＆タイマー | ✅ | [開く](day015-stopwatch-timer/index.html) |
| 016 | Markdownプレビュー | ✅ | [開く](day016-markdown-preview/index.html) |
| 017 | ガントチャート作成 | ✅ | [開く](day017-gantt-chart/index.html) |
| 018 | TODOリスト（保存対応） | ✅ | [開く](day018-todo-list/index.html) |
| 019 | ポモドーロタイマー | ✅ | [開く](day019-pomodoro/index.html) |
| 020 | おみくじ／抽選ツール | ✅ | [開く](day020-lottery/index.html) |

### フェーズ2：Python実務ツール（Day 21–40）
| Day | アプリ | 状態 | コード |
|----:|--------|:----:|:----:|
| 021 | ファイル一括リネーム | ✅ | [rename.py](day021-batch-rename/rename.py) |
| 022 | 複数CSV結合 | ✅ | [merge.py](day022-csv-merge/merge.py) |
| 023 | PDF結合・分割 | ✅ | [pdf_tool.py](day023-pdf-tool/pdf_tool.py) |
| 024 | フォルダ自動仕分け | ✅ | [organize.py](day024-file-organizer/organize.py) |
| 025 | 重複ファイル検出 | ✅ | [find_dup.py](day025-duplicate-finder/find_dup.py) |
| 026 | Excel「NG箇所」検出＆一覧化 | ✅ | [ng_finder.py](day026-excel-ng-finder/ng_finder.py) |
| 027 | テキスト一括置換 | ✅ | [replace_text.py](day027-text-replace/replace_text.py) |
| 028 | フォルダ内 横断検索 | ✅ | [search.py](day028-folder-search/search.py) |
| 029 | 文字コード一括変換 | ✅ | [convert_encoding.py](day029-encoding-convert/convert_encoding.py) |
| 030 | CSV集計・ピボット | ✅ | [aggregate.py](day030-csv-aggregate/aggregate.py) |
| 031 | CSV 列の抽出・絞り込み | ✅ | [filter_csv.py](day031-csv-filter/filter_csv.py) |
| 032 | フォルダ容量レポート | ✅ | [folder_size.py](day032-folder-size/folder_size.py) |
| 033 | フォルダ台帳CSV出力 | ✅ | [ledger.py](day033-folder-ledger/ledger.py) |
| 034 | 2ファイル差分比較 | ✅ | [diff_tool.py](day034-file-diff/diff_tool.py) |
| 035 | 日報・議事録テンプレ生成 | ✅ | [make_template.py](day035-daily-template/make_template.py) |
| 036 | ZIP一括 圧縮・解凍 | ✅ | [zip_tool.py](day036-zip-tool/zip_tool.py) |
| 037 | 差し込みテキスト量産 | ✅ | [merge_text.py](day037-mail-merge/merge_text.py) |
| 038 | PDFテキスト抽出 | ✅ | [extract_text.py](day038-pdf-extract/extract_text.py) |
| 039 | 複数Excel→1ブック集約 | ✅ | [merge_excel.py](day039-excel-merge/merge_excel.py) |
| 040 | ファイル一括 文字数・行数統計 | ✅ | [text_stats.py](day040-text-stats/text_stats.py) |

### フェーズ3：VBA / Office自動化（Day 41–65）
Excel → PowerPoint → Outlook の順で自動化ツールを作成（Office本体が必要）。

| Day | アプリ | 状態 | コード |
|----:|--------|:----:|:----:|
| 041 | 名簿からシート一括作成（Excel） | ✅ | [CreateSheetsFromList.bas](day041-vba-sheets-from-list/CreateSheetsFromList.bas) |
| 042 | 複数ブック集約（Excel） | ✅ | [ConsolidateWorkbooks.bas](day042-vba-consolidate/ConsolidateWorkbooks.bas) |
| 043 | 重複行のハイライト／削除（Excel） | ✅ | [HighlightOrRemoveDuplicates.bas](day043-vba-duplicate-rows/HighlightOrRemoveDuplicates.bas) |
| 044 | セル文字の一括整形（Excel） | ✅ | [FormatCells.bas](day044-vba-format-cells/FormatCells.bas) |
| 045 | ふりがな自動付与（Excel） | ✅ | [AddFurigana.bas](day045-vba-furigana/AddFurigana.bas) |
| 046 | 住所分割：都道府県／市区町村（Excel） | ✅ | [SplitAddress.bas](day046-vba-address-split/SplitAddress.bas) |
| 047 | 勤怠集計（Excel） | ✅ | [SummarizeAttendance.bas](day047-vba-attendance/SummarizeAttendance.bas) |
| 048 | 請求書テンプレ一括出力（Excel） | ✅ | [GenerateInvoices.bas](day048-vba-invoices/GenerateInvoices.bas) |
| 049 | グラフ一括作成（Excel） | ✅ | [CreateCharts.bas](day049-vba-charts/CreateCharts.bas) |
| 050 | 印刷範囲・ページ設定の一括適用（Excel） | ✅ | [ApplyPageSetup.bas](day050-vba-pagesetup/ApplyPageSetup.bas) |
| 051 | 不要シート・空白行の一括削除（Excel） | ✅ | [DeleteUnneeded.bas](day051-vba-cleanup/DeleteUnneeded.bas) |
| 052 | ブック内ハイパーリンク目次（Excel） | ✅ | [CreateTableOfContents.bas](day052-vba-toc/CreateTableOfContents.bas) |
| 053 | CSV取り込み整形（Excel） | ✅ | [ImportCsv.bas](day053-vba-csv-import/ImportCsv.bas) |
| 054 | 条件付き書式の一括設定（Excel） | ✅ | [ApplyConditionalFormat.bas](day054-vba-condformat/ApplyConditionalFormat.bas) |
| 055 | カレンダー自動生成（Excel） | ✅ | [GenerateCalendar.bas](day055-vba-calendar/GenerateCalendar.bas) |
| 060 | スライドの文字を一括差し替え（PowerPoint） | ✅ | [ReplaceTextInSlides.bas](day060-vba-ppt-replace-text/ReplaceTextInSlides.bas) |
| 061 | スライド内容をMarkdown化（PowerPoint） | ✅ | [ExportSlidesToMarkdown.bas](day061-vba-ppt-to-markdown/ExportSlidesToMarkdown.bas) |
| 062 | 一斉メール下書き作成：差し込み（Outlook） | ✅ | [CreateMailDrafts.bas](day062-vba-outlook-mailmerge/CreateMailDrafts.bas) |
| 063 | 受信メール一覧をExcelに書き出し（Outlook） | ✅ | [ExportInboxToExcel.bas](day063-vba-outlook-inbox-to-excel/ExportInboxToExcel.bas) |
| 064 | 添付ファイル一括保存（Outlook） | ✅ | [SaveAttachments.bas](day064-vba-outlook-save-attachments/SaveAttachments.bas) |
| 065 | 定型メールのテンプレ送信補助（Outlook） | ✅ | [TemplateMail.bas](day065-vba-outlook-template/TemplateMail.bas) |

Day 048〜059 は並行して制作中。

### フェーズ4：Flutterスマホアプリ（Day 66–90）
| Day | アプリ | 状態 | コード |
|----:|--------|:----:|:----:|
| 066 | カウンター（Flutter入門） | ✅ | [main.dart](day066-flutter-counter/lib/main.dart) |
| 067 | メモ帳 | ✅ | [main.dart](day067-flutter-memo/lib/main.dart) |
| 068 | ToDoアプリ | ✅ | [main.dart](day068-flutter-todo/lib/main.dart) |
| 069 | 買い物リスト | ✅ | [main.dart](day069-flutter-shopping/lib/main.dart) |
| 070 | 家計簿 | ✅ | [main.dart](day070-flutter-kakeibo/lib/main.dart) |
| 071 | 体重記録 | ✅ | [main.dart](day071-flutter-weight/lib/main.dart) |
| 072 | 習慣トラッカー | ✅ | [main.dart](day072-flutter-habit/lib/main.dart) |
| 073 | ストップウォッチ | ✅ | [main.dart](day073-flutter-stopwatch/lib/main.dart) |
| 074 | ポモドーロタイマー | ✅ | [main.dart](day074-flutter-pomodoro/lib/main.dart) |
| 075 | BMI計算 | ✅ | [main.dart](day075-flutter-bmi/lib/main.dart) |
| 076 | 割り勘 | ✅ | [main.dart](day076-flutter-warikan/lib/main.dart) |
| 077 | チップ計算 | ✅ | [main.dart](day077-flutter-tip/lib/main.dart) |
| 078 | 単位変換（長さ） | ✅ | [main.dart](day078-flutter-unit/lib/main.dart) |
| 079 | 為替計算（レート手入力） | ✅ | [main.dart](day079-flutter-currency/lib/main.dart) |
| 080 | パスワード生成 | ✅ | [main.dart](day080-flutter-password/lib/main.dart) |

Day 081 以降も順次追加します。

### フェーズ5：集大成アプリ（Day 91–100）

