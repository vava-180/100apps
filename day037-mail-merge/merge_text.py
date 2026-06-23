# -*- coding: utf-8 -*-
"""
差し込みテキスト量産ツール（Day 037）

CSVの名簿と、ひな形テキスト（差し込み文）から、1行（1人）ごとの文章をまとめて作ります。
例: 「{氏名} 様、いつもお世話になっております。…」を、名簿の人数分つくる。

※ このツールは文章を作るだけで、メール送信などのネット通信は一切しません。

しくみ:
  1) CSV名簿を読む（先頭行が見出し＝差し込みできる項目）
  2) ひな形テキスト（.txt）を読む。中の {見出し名} が各行の値に置き換わる
  3) 出力方法を選ぶ（1つのファイルにまとめる／1人1ファイル）

外部ライブラリは使いません（標準ライブラリ csv / io / re / sys / pathlib のみ・ネット通信なし）。
元のCSV・ひな形は書き換えません（読み取り＋新しいファイルの書き出しだけ）。
ひな形の波括弧 {…} は差し込み専用です（説明用に { を書きたいときは差し込みと混同しないよう注意）。
使い方: ターミナルで  python merge_text.py   と実行するか、ファイルをダブルクリック。
"""

import csv
import io
import re
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# Windowsでファイル名に使えない文字
INVALID_FILENAME = r'\/:*?"<>|'
# Windowsで使えない予約名（拡張子を付けても危険）
RESERVED_NAMES = {"CON", "PRN", "AUX", "NUL"}
RESERVED_NAMES |= {f"COM{i}" for i in range(1, 10)}
RESERVED_NAMES |= {f"LPT{i}" for i in range(1, 10)}

PLACEHOLDER_RE = re.compile(r"\{([^{}]+)\}")


# ===== 中心ロジック（テストしやすい純粋関数）=====

def find_placeholders(template: str):
    """ひな形の中の {見出し名} をすべて取り出して集合で返す。"""
    return set(PLACEHOLDER_RE.findall(template))


def render_row(template: str, header: list, row: list) -> str:
    """ひな形の {見出し名} を、その行の値に置き換える。

    ひな形を1回だけ走査して置換する（re.sub）。差し込んだ値の中にたまたま
    {別の見出し} という文字があっても、それは“もう一度差し込む”ことはしない。
    見出しに無い {未知} はそのまま残す（書き間違いに気づけるように）。
    """
    row_map = {}
    for i, name in enumerate(header):
        row_map[name] = row[i] if i < len(row) else ""  # 列が足りない行は空文字

    def repl(m):
        name = m.group(1)
        return row_map[name] if name in row_map else m.group(0)  # 未知はそのまま残す

    return PLACEHOLDER_RE.sub(repl, template)


def safe_filename(text: str, fallback: str) -> str:
    """ファイル名に使えない文字を _ に置き換える。空になったら fallback を使う。"""
    # 使えない記号と制御文字（改行・タブなど）を _ にする
    cleaned = "".join(
        "_" if (ch in INVALID_FILENAME or ord(ch) < 32) else ch for ch in text)
    cleaned = re.sub(r"_+", "_", cleaned)          # 連続する _ は1つにまとめる
    cleaned = cleaned.strip().strip(".").strip()   # 末尾のドット/空白はWindowsで嫌われる
    if not cleaned:
        return fallback
    if cleaned.upper() in RESERVED_NAMES:          # CON など予約名は末尾に _ を付ける
        cleaned += "_"
    return cleaned[:80]  # 長すぎる名前を避ける


# ===== ファイルの読み書き =====

def read_csv_rows(path: Path):
    """CSVを読む。(見出し, データ行, 使った文字コード, エラー文) を返す。成功時エラー文=None。"""
    try:
        raw = path.read_bytes()
    except OSError as e:
        return None, None, None, f"ファイルを読めません: {e}"
    text = None
    used_enc = None
    for enc, label in (("utf-8-sig", "UTF-8"), ("cp932", "Shift_JIS(cp932)")):
        try:
            text = raw.decode(enc)
            used_enc = label
            break
        except UnicodeDecodeError:
            continue
    if text is None:
        return None, None, None, "文字コードを判別できません（UTF-8 / Shift_JIS のどちらでもありません）。"
    try:
        all_rows = list(csv.reader(io.StringIO(text, newline=""), strict=True))
    except csv.Error as e:
        return None, None, used_enc, f"CSVの形式が壊れている可能性があります: {e}"
    if not all_rows:
        return None, None, used_enc, "中身が空です。"
    header = all_rows[0]
    data = all_rows[1:]
    if not header or all((h or "").strip() == "" for h in header):
        return None, None, used_enc, "先頭行（見出し）がありません。"
    return header, data, used_enc, None


def read_template(path: Path):
    """ひな形テキストを読む。(本文, エラー文)。成功時エラー文=None。"""
    try:
        raw = path.read_bytes()
    except OSError as e:
        return None, f"ファイルを読めません: {e}"
    for enc in ("utf-8-sig", "cp932"):
        try:
            return raw.decode(enc), None
        except UnicodeDecodeError:
            continue
    return None, "文字コードを判別できません（UTF-8 / Shift_JIS のどちらでもありません）。"


def unique_path(path: Path):
    """同名のファイル/フォルダがあれば連番を付ける。空き名が無ければ None。"""
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


def ask_file(prompt: str):
    raw = ask(prompt, "")
    if raw == "":
        print("⚠ パスが空です。")
        return None
    p = Path(raw.strip('"'))
    if not p.is_file():
        print(f"⚠ ファイルが見つかりません: {p}")
        return None
    return p


def choose_column(header: list, prompt: str):
    while True:
        raw = ask(prompt + "（番号）", "")
        if raw.isdigit():
            n = int(raw)
            if 1 <= n <= len(header):
                return n - 1
        print(f"⚠ 1〜{len(header)} の番号で入れてください。")


def main():
    print("=" * 48)
    print(" 差し込みテキスト量産ツール（Day 037）")
    print("=" * 48)
    print(" ※ 文章を作るだけです。メール送信などのネット通信はしません。")

    csv_path = ask_file("名簿CSVのパス")
    if csv_path is None:
        pause_and_exit()
        return
    header, rows, used_enc, error = read_csv_rows(csv_path)
    if error is not None:
        print(f"⚠ CSV: {error}")
        pause_and_exit()
        return
    print(f"（CSVを {used_enc} として読み込みました）")

    # 空行（全部空のセル）は差し込み対象から外す
    blank_skipped = sum(1 for r in rows if all((c or "").strip() == "" for c in r))
    rows = [r for r in rows if not all((c or "").strip() == "" for c in r)]
    if blank_skipped:
        print(f"（空行 {blank_skipped} 行は対象外にしました）")
    if not rows:
        print("⚠ 見出しだけで、差し込む名簿データがありません。")
        pause_and_exit()
        return

    # 見出しの重複・前後空白は、差し込みがうまくいかない原因になるので知らせる
    stripped = [(h or "").strip() for h in header]
    dups = sorted({h for h in stripped if h and stripped.count(h) > 1})
    if dups:
        print(f"⚠ 見出しに同じ名前があります: {dups}（差し込みは1つの列だけが使われます）")
    if any((h or "") != (h or "").strip() for h in header):
        print("⚠ 見出しの前後に空白があります。{見出し名} と一致しないことがあります。")

    print("\n--- 差し込みできる項目（見出し）---")
    for i, name in enumerate(header, start=1):
        print(f"  {i}) {name}    例: {{{name}}}")

    tpl_path = ask_file("\nひな形テキスト(.txt)のパス（中で {見出し名} が差し込まれます）")
    if tpl_path is None:
        pause_and_exit()
        return
    template, terr = read_template(tpl_path)
    if terr is not None:
        print(f"⚠ ひな形: {terr}")
        pause_and_exit()
        return
    if template.strip() == "":
        print("⚠ ひな形が空です。差し込む文章を書いてください。")
        pause_and_exit()
        return

    # ひな形に書かれた {…} のうち、見出しに無いものを知らせる（書き間違い検知）
    used = find_placeholders(template)
    unknown = sorted(used - set(header))
    if unknown:
        print(f"⚠ ひな形の差し込み {unknown} は見出しに無いので、そのまま残ります（書き間違いかも）。")
        if ask("それでも続けますか？ (yes/no)", "no").lower() not in ("yes", "y"):
            print("中止しました。ひな形の {見出し名} を見直してください。")
            pause_and_exit()
            return

    # 実際に使う見出しについて、値が空/列不足の行が何件あるか知らせる
    used_idx = [header.index(name) for name in used if name in header]
    if used_idx:
        missing = sum(
            1 for row in rows
            if any(i >= len(row) or (row[i] or "").strip() == "" for i in used_idx))
        if missing:
            print(f"⚠ 差し込み項目が空（または列不足）の行が {missing} 件あります。空欄のまま作られます。")

    # 出力方法
    print("\n出力方法を選んでください:")
    print("  1) 1つのファイルにまとめる")
    print("  2) 1人1ファイル（ファイル名に使う列を選ぶ）")
    mode = ask("番号", "1").strip()
    if mode not in ("1", "2"):
        print("⚠ 1 か 2 を選んでください。")
        pause_and_exit()
        return
    name_idx = choose_column(header, "ファイル名に使う列") if mode == "2" else None

    # プレビュー（1件目）
    print("\n--- プレビュー（1件目）---")
    for line in render_row(template, header, rows[0]).splitlines():
        print("  " + line)

    if ask(f"\n{len(rows)} 件を書き出しますか？ (yes/no)", "no").lower() not in ("yes", "y"):
        print("書き出しませんでした。プレビューのみです。")
        pause_and_exit()
        return

    out_dir = csv_path.parent
    if mode == "1":
        # 1ファイルにまとめる（区切り線で各件を分ける）
        body = ("\n\n" + "-" * 40 + "\n\n").join(
            render_row(template, header, row) for row in rows)
        out = unique_path(out_dir / "差し込み結果.txt")
        if out is None:
            print("⚠ 出力ファイル名を用意できませんでした。")
            pause_and_exit()
            return
        try:
            with open(out, "x", encoding="utf-8") as f:
                f.write(body)
        except OSError as e:
            print(f"⚠ 書き出しに失敗しました: {e}")
            pause_and_exit()
            return
        print(f"\n✅ {len(rows)} 件を書き出しました:\n   {out}")
    else:
        # 1人1ファイル（専用フォルダにまとめる）
        folder = unique_path(out_dir / "差し込み出力")
        if folder is None:
            print("⚠ 出力フォルダ名を用意できませんでした。")
            pause_and_exit()
            return
        try:
            folder.mkdir()
        except OSError as e:
            print(f"⚠ 出力フォルダを作れませんでした: {e}")
            pause_and_exit()
            return
        done = 0
        for n, row in enumerate(rows, start=1):
            label = row[name_idx] if name_idx < len(row) else ""
            fname = safe_filename(label, f"{n:04d}") + ".txt"
            out = unique_path(folder / fname)
            if out is None:
                print(f"⚠ {n} 件目: ファイル名を用意できませんでした。飛ばします。")
                continue
            try:
                with open(out, "x", encoding="utf-8") as f:
                    f.write(render_row(template, header, row))
                done += 1
            except OSError as e:
                print(f"⚠ {n} 件目を飛ばしました … {e}")
        print(f"\n✅ {done} / {len(rows)} 件を書き出しました:\n   {folder}/")

    pause_and_exit()


if __name__ == "__main__":
    main()
