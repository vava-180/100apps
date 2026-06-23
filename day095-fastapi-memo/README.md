# Day 095: 簡易メモ帳API（Python + FastAPI・ローカル）

自分のパソコンの中だけで動く、小さなWeb APIです。メモを「一覧・作成・取得・削除」できます。FastAPI が自動で作る操作画面（`/docs`）から、ブラウザで試せます。

## 必要なもの
- Python 3
- FastAPI / uvicorn … `pip install -r requirements.txt`

## 使い方
1. このフォルダで初回だけ：`pip install -r requirements.txt`
2. サーバーを起動：`uvicorn main:app --reload`
3. ブラウザで `http://127.0.0.1:8000/docs` を開く
4. 画面から各APIを実行できる（一覧 / 作成 / 取得 / 削除）

## APIの一覧
| メソッド | パス | 内容 |
|---|---|---|
| GET | `/memos` | メモを全件返す |
| POST | `/memos` | メモを作る（本文 text を渡す） |
| GET | `/memos/{id}` | メモを1件返す |
| DELETE | `/memos/{id}` | メモを1件消す |

## 機能
- メモの作成・一覧・取得・削除（CRUDの基本）
- 入力チェック：本文は前後空白を除いて1〜200文字（空・空白のみ・長すぎは 422）
- 適切なHTTPステータス（作成=201 / 見つからない=404 / 入力エラー=422）
- 同時アクセスでもid番号がぶつからないよう鍵（Lock）で保護
- 作成日時はUTCで記録

## 使った技術
- Python / FastAPI / Pydantic（uvicornで起動）

## 学び・ポイント
- 入力の整形・検証は Pydantic の `field_validator` にまとめると、APIの仕様・自動ドキュメント・エラー形式がそろう
- 連番のidは `global` 変数だけだと同時アクセスで重複しうるので、`threading.Lock` で囲む
- 日時は `datetime.now(timezone.utc)` のようにタイムゾーン付きで持つと、後で扱いやすい
- 返す形は `response_model` で型を決めると、`/docs` の表示も正確になる

## 注意
- これは外部のネットサービスを呼ぶものではなく、自分のPC内（localhost）で動くサーバーです。
- データはメモリ上だけ。サーバーを止めると消えます（練習用）。

---
100日100アプリチャレンジ Day 095 / 100
