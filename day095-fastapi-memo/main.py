# -*- coding: utf-8 -*-
"""
簡易メモ帳API（Day 095 / Python + FastAPI・ローカル）

ローカル（自分のパソコンの中）だけで動く、小さなWeb APIです。
メモを「一覧・作成・取得・削除」できます。データはメモリ上に置くだけなので、
サーバーを止めると消えます（練習用）。

起動:
  pip install fastapi uvicorn        ← 初回だけ
  uvicorn main:app --reload

確認:
  ブラウザで http://127.0.0.1:8000/docs を開くと、画面から各APIを試せます。

注意: これは外部のネットサービスを呼ぶものではなく、自分のPC内で動くサーバーです。
"""

from datetime import datetime, timezone
from threading import Lock

from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse
from pydantic import BaseModel, Field, field_validator

# アプリ本体を作る（タイトルなどは /docs に表示される）
app = FastAPI(title="メモ帳API", description="Day 095 のローカル練習用API", version="1.0")

# ===== データの形（スキーマ）=====

class MemoIn(BaseModel):
    """メモを作る・受け取るときの入力。前後の空白を除いて1〜200文字。"""
    text: str = Field(..., description="メモの本文（前後空白を除いて1〜200文字）")

    @field_validator("text")
    @classmethod
    def clean_text(cls, value: str) -> str:
        # 前後の空白を取り除いてから長さを確かめる（空白だけの入力もここで弾く）
        value = value.strip()
        if not value:
            raise ValueError("本文が空です。")
        if len(value) > 200:
            raise ValueError("本文は200文字以内にしてください。")
        return value


class Memo(BaseModel):
    """APIが返すメモ。idと作成日時が付く。"""
    id: int
    text: str
    created_at: datetime


class DeleteResult(BaseModel):
    """削除APIが返す結果。"""
    deleted: int


# ===== データの置き場所（メモリ上）=====
memos: dict[int, Memo] = {}   # id をキーにしてメモを保管
next_id = 1                   # 次に振る番号
data_lock = Lock()            # 同時アクセスでid採番がぶつからないようにする鍵


# ===== ルート（おまけの案内ページ）=====
@app.get("/", response_class=HTMLResponse)
def index():
    """トップページ。使い方の案内を表示する。"""
    return """
    <h1>メモ帳API（Day 095）</h1>
    <p>これはローカルで動く練習用APIです。</p>
    <p>操作画面 → <a href="/docs">/docs</a></p>
    """


# ===== メモの一覧を返す =====
@app.get("/memos", response_model=list[Memo])
def list_memos():
    """登録されているメモを、id順に全部返す。"""
    return [memos[k] for k in sorted(memos)]


# ===== メモを1件作る =====
@app.post("/memos", response_model=Memo, status_code=201)
def create_memo(memo_in: MemoIn):
    """新しいメモを作る。本文の検証・整形は MemoIn 側で済んでいる。"""
    global next_id
    # id採番と保存をまとめて鍵で囲む（同時に作っても番号が重複しない）
    with data_lock:
        memo = Memo(id=next_id, text=memo_in.text, created_at=datetime.now(timezone.utc))
        memos[next_id] = memo
        next_id += 1
    return memo


# ===== メモを1件取得する =====
@app.get("/memos/{memo_id}", response_model=Memo)
def get_memo(memo_id: int):
    """idを指定して1件だけ返す。無ければ404。"""
    memo = memos.get(memo_id)
    if memo is None:
        raise HTTPException(status_code=404, detail="そのメモは見つかりません。")
    return memo


# ===== メモを1件削除する =====
@app.delete("/memos/{memo_id}", response_model=DeleteResult)
def delete_memo(memo_id: int):
    """idを指定して削除する。無ければ404。"""
    with data_lock:
        if memo_id not in memos:
            raise HTTPException(status_code=404, detail="そのメモは見つかりません。")
        del memos[memo_id]
    return DeleteResult(deleted=memo_id)
