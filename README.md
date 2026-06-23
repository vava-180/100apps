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

Day 031 以降も順次追加予定。

### フェーズ3：VBA / Office自動化（Day 41–65）
Excel→PowerPoint自動貼り付け、Outlook一括下書き、書類の差し込み量産 など

### フェーズ4：Flutterスマホアプリ（Day 66–90）

### フェーズ5：集大成アプリ（Day 91–100）

