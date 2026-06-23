# -*- coding: utf-8 -*-
"""
ファイル一括 文字数・行数統計ツール（Day 040）

フォルダの中のテキストファイルごとに、行数・文字数・単語数を数えて一覧表示します。
原稿やコードの分量をまとめて把握したいときに使えます。

しくみ:
  1) フォルダ内のテキストファイルを集める（サブフォルダ・拡張子の指定ができる）
  2) 各ファイルの 行数 / 文字数 / 空白を除いた文字数 / 単語数 を数える
  3) 合計とともに一覧表示し、任意でCSVに書き出す

外部ライブラリは使いません（標準ライブラリ os / csv / sys / pathlib のみ・ネット通信なし）。
このツールはファイルを書き換えません（数えて表示・CSV出力するだけ）。
使い方: ターミナルで  python text_stats.py   と実行するか、ファイルをダブルクリック。
"""

import csv
import os
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# 中身を読む1ファイルの大きさの上限（これより大きいファイルは数えない）
MAX_BYTES = 20 * 1024 * 1024  # 20MB


# ===== 中心ロジック（テストしやすい純粋関数）=====

def count_text(text: str) -> dict:
    """テキストの 行数 / 文字数 / 空白を除いた文字数 / 単語数 を数えて辞書で返す。

    - 行数: 改行で区切った行の数。例: ""=0行 / "a"=1行 / "a\\n"=1行 / "a\\nb"=2行
    - 文字数: すべての文字の数（改行や空白も含む）
    - 文字数(空白除く): 空白・改行・タブなどを除いた文字数
    - 単語数: 空白で区切ったかたまりの数（日本語は空白が無いと1かたまりになる点に注意）
    """
    lines = len(text.splitlines())
    chars = len(text)
    chars_no_space = sum(1 for ch in text if not ch.isspace())
    words = len(text.split())
    return {"lines": lines, "chars": chars, "chars_no_space": chars_no_space, "words": words}


def normalize_exts(raw: str) -> list:
    """「.txt, md ,.py」のような入力を ['.txt', '.md', '.py'] に整える。"""
    exts = []
    for part in raw.replace("，", ",").split(","):
        e = part.strip().lower()
        if not e:
            continue
        if not e.startswith("."):
            e = "." + e
        if e not in exts:
            exts.append(e)
    return exts


def csv_safe(text: str) -> str:
    """Excelで数式と誤解されないよう、危険な記号で始まる文字列の先頭に ' を付ける。

    先頭に空白を入れて回避されないよう、空白を除いた先頭文字も確認する。
    タブ・改行で始まる値も同様に無害化する。
    """
    stripped = text.lstrip()
    if stripped and stripped[0] in ("=", "+", "-", "@"):
        return "'" + text
    if text[:1] in ("\t", "\r", "\n"):
        return "'" + text
    return text


# ===== ファイルの読み取り =====

def read_text(path: Path):
    """テキストを読む。読めなければ None（大きすぎる・バイナリ・文字コード不明）。"""
    try:
        if path.stat().st_size > MAX_BYTES:
            return None
        raw = path.read_bytes()
    except OSError:
        return None
    if len(raw) > MAX_BYTES:  # 念のため、読み込んだ後の大きさでも確認
        return None
    # ヌル文字＝画像などのバイナリ（NULを含まないバイナリは見逃すので完全な判定ではない）
    if b"\x00" in raw:
        return None
    for enc in ("utf-8-sig", "cp932"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return None


def collect_files(folder: Path, recursive: bool, exts: list, self_path: Path):
    """対象ファイルを集める。(ファイル一覧, 走査中に飛ばした数) を返す。

    「.」で始まる隠しフォルダ／ファイルと、自分自身（このスクリプト）は除く。
    """
    try:
        self_resolved = self_path.resolve()
    except OSError:
        self_resolved = None
    files = []
    skipped = 0

    def on_error(_e):
        nonlocal skipped
        skipped += 1

    for root, dirs, names in os.walk(folder, onerror=on_error, followlinks=False):
        dirs[:] = [d for d in dirs if not d.startswith(".")]  # 「.」で始まるフォルダへ降りない
        if not recursive:
            dirs[:] = []
        for name in names:
            if name.startswith("."):
                continue
            p = Path(root) / name
            if exts and p.suffix.lower() not in exts:
                continue
            try:
                if self_resolved is not None and p.resolve() == self_resolved:
                    continue
            except OSError:
                skipped += 1
                continue
            files.append(p)
    return files, skipped


# ===== ファイル書き出し =====

def unique_path(path: Path):
    """同名ファイルがあれば連番を付ける。空き名が無ければ None。"""
    if not path.exists():
        return path
    for i in range(2, 1000):
        cand = path.with_name(f"{path.stem}({i}){path.suffix}")
        if not cand.exists():
            return cand
    return None


def write_csv(path: Path, rows: list):
    """統計をCSVに書き出す。Excelで開きやすい UTF-8（BOM付き）。"x"で上書きしない。"""
    header = ["相対パス", "行数", "文字数", "文字数(空白除く)", "単語数(空白区切り)"]
    with open(path, "x", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(header)
        for rel, st in rows:
            writer.writerow([csv_safe(rel), st["lines"], st["chars"],
                             st["chars_no_space"], st["words"]])


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
    print(" ファイル一括 文字数・行数統計ツール（Day 040）")
    print("=" * 48)

    here = str(Path(__file__).parent)
    folder = Path(ask("調べたいフォルダのパス", here).strip().strip('"').strip("'"))
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    exts = normalize_exts(ask("対象の拡張子（カンマ区切り。空Enterで .txt,.md）", ".txt,.md"))
    recursive = ask("サブフォルダの中も対象にしますか？ (yes/no)", "yes").lower() in ("yes", "y")

    print("\n集めています…")
    files, walk_skipped = collect_files(folder, recursive, exts, Path(__file__))
    if not files:
        print("対象ファイルが見つかりませんでした。")
        pause_and_exit()
        return

    rows = []          # (相対パス, 統計dict)
    unreadable = 0     # 読めなかった（大きすぎる・バイナリなど）
    for p in sorted(files, key=lambda x: x.relative_to(folder).as_posix().lower()):
        text = read_text(p)
        if text is None:
            unreadable += 1
            continue
        rows.append((p.relative_to(folder).as_posix(), count_text(text)))

    if not rows:
        print("中身を読めるテキストファイルがありませんでした。")
        pause_and_exit()
        return

    # 合計
    total = {"lines": 0, "chars": 0, "chars_no_space": 0, "words": 0}
    for _rel, st in rows:
        for k in total:
            total[k] += st[k]

    print(f"\n--- 統計（{len(rows)} ファイル）---")
    print(f"  {'行数':>8} {'文字数':>9} {'空白除く':>9} {'単語数':>8}  ファイル")
    for rel, st in rows[:20]:
        print(f"  {st['lines']:>8} {st['chars']:>9} {st['chars_no_space']:>9} {st['words']:>8}  {rel}")
    if len(rows) > 20:
        print(f"  … ほか {len(rows) - 20} ファイル（全体はCSV出力で確認できます）")
    print(f"  {'-'*44}")
    print(f"  {total['lines']:>8} {total['chars']:>9} {total['chars_no_space']:>9} {total['words']:>8}  合計")

    if walk_skipped or unreadable:
        print(f"\n（飛ばした項目: 走査中 {walk_skipped} 件 / 読めない(大きすぎ・バイナリ等) {unreadable} 件）")

    if ask("\nこの結果をCSVに書き出しますか？ (yes/no)", "no").lower() in ("yes", "y"):
        base = folder / "文字数統計.csv"
        out = None
        for _ in range(5):
            cand = unique_path(base)
            if cand is None:
                break
            try:
                write_csv(cand, rows)
                out = cand
                break
            except FileExistsError:
                continue
            except OSError as e:
                print(f"⚠ 書き出しに失敗しました: {e}")
                break
        if out is not None:
            print(f"✅ 書き出しました: {out}")
        else:
            print("⚠ 別名ファイルを用意できず、書き出せませんでした。")

    pause_and_exit()


if __name__ == "__main__":
    main()
