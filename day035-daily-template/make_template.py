# -*- coding: utf-8 -*-
"""
日報・議事録テンプレ自動生成ツール（Day 035）

「日報」「議事録」「週報」などの定型フォーマットを、日付入りで自動生成します。
毎日ゼロから書き出す手間を減らし、書く項目（見出し）を先に用意します。

しくみ:
  1) テンプレの種類を選ぶ（日報／議事録／週報）
  2) 日付を入れる（空Enterなら今日）
  3) 日付や曜日を埋め込んだファイル（例: 2026-06-23_日報.md）を書き出す

外部ライブラリは使いません（標準ライブラリ datetime / pathlib / sys のみ・ネット通信なし）。
既にあるファイルは上書きしません（連番を付けて新規作成）。
使い方: ターミナルで  python make_template.py   と実行するか、ファイルをダブルクリック。
"""

import sys
from datetime import date, datetime, timedelta
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# 曜日（月曜=0）を日本語にする表
WEEKDAYS_JP = ["月", "火", "水", "木", "金", "土", "日"]

# テンプレの種類 → (ファイル名に使う語, 本文のひな形)
# {date} = 2026-06-23 / {weekday} = 月 / {date_jp} = 2026年6月23日(月) / {week_range} = 週の範囲
TEMPLATES = {
    "1": ("日報", """# 日報 {date_jp}

## 今日やったこと
-

## 進捗・成果
-

## 課題・困りごと
-

## 明日の予定
-

## ひとことメモ
-
"""),
    "2": ("議事録", """# 議事録 {date_jp}

- 日時: {date_jp}
- 場所:
- 参加者:

## 議題
1.

## 決定事項
-

## ToDo（担当 / 期限）
- [ ] 内容（担当: / 期限: ）

## 次回
- 日時:
- 議題:
"""),
    "3": ("週報", """# 週報 {date_jp}（{week_range} の週）

## 今週やったこと
-

## 成果・数字
-

## 来週の予定
-

## 課題・相談したいこと
-
"""),
}


# ===== 中心ロジック（テストしやすい純粋関数）=====

def parse_date(text: str):
    """'2026-06-23' のような文字列を date にする。空なら今日。読めなければ None。"""
    text = text.strip()
    if text == "":
        return date.today()
    # 区切りは - でも / でも受け付ける
    normalized = text.replace("/", "-")
    try:
        return datetime.strptime(normalized, "%Y-%m-%d").date()
    except ValueError:
        return None


def jp_weekday(d: date) -> str:
    """date を「月」「火」…の日本語曜日にする。"""
    return WEEKDAYS_JP[d.weekday()]


def week_range(d: date):
    """その日が属する週（月曜〜日曜）の範囲を 'YYYY/M/D〜YYYY/M/D' で返す。

    年をまたぐ週でも、どちらの年か分かるように年を付ける。
    """
    monday = d - timedelta(days=d.weekday())
    sunday = monday + timedelta(days=6)
    return (f"{monday.year}/{monday.month}/{monday.day}"
            f"〜{sunday.year}/{sunday.month}/{sunday.day}")


def render(template_body: str, d: date) -> str:
    """ひな形の {date} などを、実際の日付に置き換える。

    str.format は使わない。テンプレ本文に普通の波括弧（例: {メモ} {担当}）が
    混ざっていても壊れないよう、決めた4つの語だけを replace で置き換える。
    """
    values = {
        "date": d.strftime("%Y-%m-%d"),
        "weekday": jp_weekday(d),
        "date_jp": f"{d.year}年{d.month}月{d.day}日({jp_weekday(d)})",
        "week_range": week_range(d),
    }
    result = template_body
    for key, value in values.items():
        result = result.replace("{" + key + "}", value)
    return result


def build_filename(d: date, label: str) -> str:
    """'2026-06-23_日報.md' のようなファイル名を作る。"""
    return f"{d.strftime('%Y-%m-%d')}_{label}.md"


# ===== ファイル書き出し =====

def unique_path(path: Path):
    """同名ファイルがあれば連番を付けて、既存を上書きしない。空き名が見つからなければ None。"""
    if not path.exists():
        return path
    for i in range(2, 1000):
        cand = path.with_name(f"{path.stem}({i}){path.suffix}")
        if not cand.exists():
            return cand
    return None


# ===== 画面とのやり取り =====

def ask(prompt: str, default: str = "") -> str:
    suffix = f"（未入力なら {default}）" if default else ""
    try:
        value = input(f"{prompt}{suffix}: ").strip()
    except EOFError:
        return default
    return value if value else default


def pause_and_exit():
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass


def main():
    print("=" * 48)
    print(" 日報・議事録テンプレ自動生成ツール（Day 035）")
    print("=" * 48)

    print("\nどのテンプレを作りますか？")
    for key, (label, _body) in TEMPLATES.items():
        print(f"  {key}) {label}")
    choice = ask("番号", "1").strip()
    if choice not in TEMPLATES:
        print("⚠ 番号が正しくありません。")
        pause_and_exit()
        return
    label, body = TEMPLATES[choice]

    d = parse_date(ask("日付（YYYY-MM-DD。空Enterで今日）", ""))
    if d is None:
        print("⚠ 日付の形式が正しくありません（例: 2026-06-23）。")
        pause_and_exit()
        return

    here = str(Path(__file__).parent)
    folder = Path(ask("保存先フォルダ", here).strip('"'))
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    content = render(body, d)

    # --- プレビュー ---
    print(f"\n--- プレビュー（{build_filename(d, label)}）---")
    for line in content.splitlines():
        print("  " + line)

    if ask("\nこの内容でファイルを作りますか？ (yes/no)", "yes").lower() not in ("yes", "y"):
        print("作成しませんでした。プレビューのみです。")
        pause_and_exit()
        return

    base = folder / build_filename(d, label)
    out = None
    for _ in range(5):
        cand = unique_path(base)
        if cand is None:
            break
        try:
            with open(cand, "x", encoding="utf-8") as f:
                f.write(content)
            out = cand
            break
        except FileExistsError:
            continue
        except OSError as e:
            print(f"⚠ 書き出しに失敗しました: {e}")
            pause_and_exit()
            return
    if out is None:
        print("⚠ 書き出し先の名前が用意できませんでした。")
        pause_and_exit()
        return

    print(f"\n✅ 作成しました:\n   {out}")
    pause_and_exit()


if __name__ == "__main__":
    main()
