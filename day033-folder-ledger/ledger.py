# -*- coding: utf-8 -*-
"""
フォルダ台帳CSV出力ツール（Day 033）

フォルダの中のファイルを一覧にして、「名前・相対パス・拡張子・サイズ・更新日時」を
CSV（台帳）に書き出します。資産の棚卸しや、ファイル一覧の提出などに使えます。

しくみ:
  1) フォルダ内のファイルを集める（サブフォルダも対象にできる）
  2) 各ファイルの情報（サイズ・更新日時など）を読む
  3) 1行1ファイルのCSVに書き出す（相対パス順）

外部ライブラリは使いません（標準ライブラリ os / csv / re / datetime / pathlib のみ・ネット通信なし）。
このツールはファイルを移動・削除しません（読み取り＋CSV1枚の書き出しだけ）。
使い方: ターミナルで  python ledger.py   と実行するか、ファイルをダブルクリック。
"""

import csv
import os
import re
import sys
from datetime import datetime
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# このツールが書き出す台帳ファイルの名前（再実行時に自分の出力を巻き込まないため）
LEDGER_PREFIX = "ファイル台帳"
# 「ファイル台帳.csv」「ファイル台帳(2).csv」など、自分が作った形だけを除外する
LEDGER_RE = re.compile(r"^ファイル台帳(\(\d+\))?\.csv$")


# ===== 中心ロジック（テストしやすい純粋関数）=====

def human_size(num_bytes: int) -> str:
    """バイト数を読みやすい単位にする（1024ごとに KB→MB→GB…、いわゆる1024基準）。"""
    units = ["B", "KB", "MB", "GB", "TB", "PB"]
    size = float(num_bytes)
    i = 0
    while size >= 1024 and i < len(units) - 1:
        size /= 1024
        i += 1
    if i == 0:
        return f"{int(num_bytes)} B"
    return f"{size:.1f} {units[i]}"


def file_row(path: Path, folder: Path):
    """1ファイル分の台帳の行を作る。読めなければ None。

    返す列: [相対パス, 名前, 拡張子, サイズ(バイト), サイズ(読みやすい), 更新日時]
    """
    try:
        st = path.stat()
    except OSError:
        return None
    rel = path.relative_to(folder).as_posix()  # 区切りを / にそろえて見やすく
    ext = path.suffix.lower()
    mtime = datetime.fromtimestamp(st.st_mtime).strftime("%Y-%m-%d %H:%M:%S")
    return [rel, path.name, ext, st.st_size, human_size(st.st_size), mtime]


def csv_safe(text: str) -> str:
    """Excelで数式と誤解されないよう、危険な記号で始まる文字列の先頭に ' を付ける。

    ファイル名は外から来るので、'=cmd' のような名前がCSV→Excelで数式実行されるのを防ぐ。
    """
    if text and text[0] in ("=", "+", "-", "@"):
        return "'" + text
    return text


def collect_files(folder: Path, recursive: bool, include_hidden: bool, self_path: Path):
    """対象ファイルを集める。(ファイル一覧, 読めず飛ばした数) を返す。

    除くもの: 自分自身（このスクリプト）、このツールが過去に出した台帳CSV。
    include_hidden=False のときは、隠しフォルダ（「.」始まり）には最初から降りない。
    """
    try:
        self_resolved = self_path.resolve()
    except OSError:
        self_resolved = None
    files = []
    skipped = 0

    def on_error(_e):
        nonlocal skipped
        skipped += 1  # フォルダをたどる途中の権限エラーなど

    # os.walk は dirs を書き換えると「その先へ降りない」ようにできる（隠し除外・非再帰に使う）
    for root, dirs, names in os.walk(folder, onerror=on_error, followlinks=False):
        if not include_hidden:
            dirs[:] = [d for d in dirs if not d.startswith(".")]  # 隠しフォルダへ降りない
        if not recursive:
            dirs[:] = []  # サブフォルダへ降りない（直下だけ）
        for name in names:
            if not include_hidden and name.startswith("."):
                continue  # 隠しファイル
            if LEDGER_RE.match(name):
                continue  # 過去に自分が出した台帳を巻き込まない
            p = Path(root) / name
            try:
                if self_resolved is not None and p.resolve() == self_resolved:
                    continue  # 本物の自分（このスクリプト）だけを確実に除く
            except OSError:
                skipped += 1
                continue
            files.append(p)
    return files, skipped


# ===== ファイル書き出し =====

def unique_path(path: Path) -> Path:
    """同名ファイルがあれば連番を付けて、既存を上書きしない。"""
    if not path.exists():
        return path
    i = 2
    while True:
        cand = path.with_name(f"{path.stem}({i}){path.suffix}")
        if not cand.exists():
            return cand
        i += 1


def write_ledger(path: Path, rows: list):
    """台帳をCSVに書き出す。Excelで開きやすい UTF-8（BOM付き）。"x"で上書きしない。"""
    header = ["相対パス", "名前", "拡張子", "サイズ(バイト)", "サイズ(読みやすい)", "更新日時(ローカル)"]
    with open(path, "x", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for r in rows:
            # 文字の列（相対パス・名前・拡張子）だけ、Excel数式扱い対策をかける
            writer.writerow([csv_safe(r[0]), csv_safe(r[1]), csv_safe(r[2]), r[3], r[4], r[5]])


# ===== 画面とのやり取り =====

def ask(prompt: str, default: str = "") -> str:
    suffix = f"（未入力なら {default}）" if default else ""
    value = input(f"{prompt}{suffix}: ").strip()
    return value if value else default


def pause_and_exit():
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass


def main():
    print("=" * 48)
    print(" フォルダ台帳CSV出力ツール（Day 033）")
    print("=" * 48)

    here = str(Path(__file__).parent)
    raw = ask("一覧にしたいフォルダのパス", here)
    folder = Path(raw.strip('"'))
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    recursive = ask("サブフォルダの中も対象にしますか？ (yes/no)", "yes").lower() in ("yes", "y")
    include_hidden = ask("「.」で始まる隠しフォルダも含めますか？ (yes/no)", "no").lower() in ("yes", "y")

    print("\n集めています…")
    files, skipped = collect_files(folder, recursive, include_hidden, Path(__file__))
    if not files:
        print("対象ファイルが見つかりませんでした。")
        pause_and_exit()
        return

    rows = []
    read_skipped = 0
    for p in sorted(files, key=lambda x: x.relative_to(folder).as_posix().lower()):
        row = file_row(p, folder)
        if row is None:
            read_skipped += 1
            continue
        rows.append(row)

    if not rows:
        print("ファイル情報を読めませんでした。")
        pause_and_exit()
        return

    total_bytes = sum(r[3] for r in rows)
    print(f"\n--- 台帳プレビュー（{len(rows)} ファイル / 合計 {human_size(total_bytes)} ）---")
    print(f"  {'サイズ':>10}  更新日時             相対パス")
    for r in rows[:10]:
        print(f"  {r[4]:>10}  {r[5]}  {r[0]}")
    if len(rows) > 10:
        print(f"  … ほか {len(rows) - 10} ファイル")
    if skipped or read_skipped:
        print(f"\n（読めず飛ばした項目: 走査中 {skipped} 件 / 情報取得 {read_skipped} 件）")

    if ask("\nこの内容でCSV台帳に書き出しますか？ (yes/no)", "yes").lower() not in ("yes", "y"):
        print("書き出しませんでした。プレビューのみです。")
        pause_and_exit()
        return

    base = folder / f"{LEDGER_PREFIX}.csv"
    out = None
    for _ in range(5):
        cand = unique_path(base)
        try:
            write_ledger(cand, rows)
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

    print(f"\n✅ 完了しました。{len(rows)} ファイルを台帳に書き出しました:\n   {out}")
    pause_and_exit()


if __name__ == "__main__":
    main()
