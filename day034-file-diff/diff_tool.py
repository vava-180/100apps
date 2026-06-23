# -*- coding: utf-8 -*-
"""
2ファイル差分比較ツール（Day 034）

2つのテキストファイルを比べて、「どの行が増えた／減った／変わった」かを表示します。
任意で、左右に並べて色分けした差分をHTMLに書き出し、ブラウザで見られます。

しくみ:
  1) 2つのファイルを読む（文字コードは UTF-8 / Shift_JIS を自動判別）
  2) 行ごとに比べて、追加(+)・削除(-)の行を表示する
  3) 希望すれば、左右並びのHTML差分レポートを書き出す

外部ライブラリは使いません（標準ライブラリ difflib / re / pathlib のみ・ネット通信なし）。
HTMLは手元で完結するファイルで、ネット通信はしません。元ファイルは書き換えません。
※ 比べるのは「行の内容」です。改行コード（LF/CRLF）の違いや末尾改行の有無は見ません。
使い方: ターミナルで  python diff_tool.py   と実行するか、ファイルをダブルクリック。
"""

import difflib
import re
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# コンソールに出す差分行の上限（多すぎる時に画面が埋まらないように）
MAX_DIFF_LINES = 200


# ===== 中心ロジック（テストしやすい純粋関数）=====

def count_changes(a_lines: list, b_lines: list):
    """2つの行リストを比べて (追加行数, 削除行数, 変更ブロック数) を返す。

    difflib の opcodes を使う:
      replace=変更, delete=削除, insert=追加, equal=同じ。
    変更(replace)は「削除＋追加」の行数として数えつつ、変更の「まとまり数」も別に数える。
    ※ 3つ目は「変更行数」ではなく、連続して変わった“ブロックの個数”。
    autojunk=False… 同じ行が多いファイルでも、間引きせず素直に比較する。
    """
    sm = difflib.SequenceMatcher(None, a_lines, b_lines, autojunk=False)
    added = removed = changed = 0
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "insert":
            added += (j2 - j1)
        elif tag == "delete":
            removed += (i2 - i1)
        elif tag == "replace":
            removed += (i2 - i1)
            added += (j2 - j1)
            changed += 1
    return added, removed, changed


def unified_lines(a_lines: list, b_lines: list, a_name: str, b_name: str):
    """差分を「+/-」付きの行リストにして返す（unified diff 形式）。"""
    return list(difflib.unified_diff(
        a_lines, b_lines,
        fromfile=a_name, tofile=b_name,
        lineterm="",  # 行末の改行は付けない（自分でprintするため）
    ))


def html_report(a_lines: list, b_lines: list, a_name: str, b_name: str) -> str:
    """左右に並べたHTML差分（色分け）を作る。中身は自己完結でネット通信なし。"""
    maker = difflib.HtmlDiff(wrapcolumn=80)  # 長い行は80桁で折り返す
    # context=False … 差分の周辺だけでなく、ファイル全体を左右に並べて見せる
    html = maker.make_file(a_lines, b_lines, a_name, b_name, context=False)
    # 標準の出力は先頭に W3C のDTD URL付きDOCTYPEが入る（ブラウザは読みに行かないが、
    # 「ネット参照なし」を明確にするため HTML5 のDOCTYPEに置き換えて完全自己完結にする）
    return re.sub(r"<!DOCTYPE.*?>", "<!DOCTYPE html>", html, count=1, flags=re.DOTALL | re.IGNORECASE)


# ===== ファイルの読み取り =====

def read_lines(path: Path):
    """テキストを行リストにして返す。(行リスト, 文字コード名, エラー文) を返す。成功時エラー文=None。

    文字コードは UTF-8（BOM有無）→ Shift_JIS(cp932) の順。画像などのバイナリは対象外。
    """
    try:
        raw = path.read_bytes()
    except OSError as e:
        return None, None, f"ファイルを読めません: {e}"
    if b"\x00" in raw:  # ヌル文字を含む＝画像などのバイナリとみなす
        return None, None, "テキストではないファイル（バイナリ）のようです。"
    for enc, label in (("utf-8-sig", "UTF-8"), ("cp932", "Shift_JIS(cp932)")):
        try:
            text = raw.decode(enc)
        except UnicodeDecodeError:
            continue
        if looks_binary(text):
            # cp932 はほぼ何でも読めてしまうので、制御文字だらけならバイナリ扱いにする
            return None, None, "テキストではないファイル（バイナリ）のようです。"
        return text.splitlines(), label, None
    return None, None, "文字コードを判別できません（UTF-8 / Shift_JIS のどちらでもありません）。"


def looks_binary(text: str) -> bool:
    """制御文字（タブ・改行以外）が多すぎる場合に、バイナリらしいと判断する。"""
    if not text:
        return False
    allowed = ("\t", "\n", "\r")
    ctrl = sum(1 for ch in text if ord(ch) < 32 and ch not in allowed)
    return ctrl / len(text) > 0.1  # 1割を超えて制御文字ならバイナリ寄り


def unique_path(path: Path):
    """同名ファイルがあれば連番を付けて、既存を上書きしない。見つからなければ None。"""
    if not path.exists():
        return path
    for i in range(2, 1000):  # 上限を付けて無限ループにしない
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
        return default  # 標準入力が閉じている環境でも落ちないように
    return value if value else default


def pause_and_exit():
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass


def ask_file(prompt: str):
    """ファイルパスを聞いて、存在するファイルなら Path を返す。だめなら None。"""
    raw = ask(prompt, "")
    if raw == "":
        print("⚠ パスが空です。")
        return None
    p = Path(raw.strip('"'))
    if not p.is_file():
        print(f"⚠ ファイルが見つかりません: {p}")
        return None
    return p


def main():
    print("=" * 48)
    print(" 2ファイル差分比較ツール（Day 034）")
    print("=" * 48)

    path_a = ask_file("比べるファイル1（元）のパス")
    if path_a is None:
        pause_and_exit()
        return
    path_b = ask_file("比べるファイル2（新）のパス")
    if path_b is None:
        pause_and_exit()
        return

    a_lines, a_enc, a_err = read_lines(path_a)
    if a_err is not None:
        print(f"⚠ ファイル1: {a_err}")
        pause_and_exit()
        return
    b_lines, b_enc, b_err = read_lines(path_b)
    if b_err is not None:
        print(f"⚠ ファイル2: {b_err}")
        pause_and_exit()
        return
    print(f"（ファイル1: {a_enc} ／ ファイル2: {b_enc} として読み込みました）")

    added, removed, changed = count_changes(a_lines, b_lines)
    if added == 0 and removed == 0:
        print("\n2つのファイルは行の内容が同じです（改行コードの違いは見ていません）。")
        pause_and_exit()
        return

    print(f"\n--- 差分の概要 ---")
    print(f"  追加された行: {added}")
    print(f"  削除された行: {removed}")
    print(f"  変わったまとまり: {changed}")

    print("\n--- 差分（+ は追加、- は削除）---")
    diff = unified_lines(a_lines, b_lines, path_a.name, path_b.name)
    for line in diff[:MAX_DIFF_LINES]:
        print("  " + line)
    if len(diff) > MAX_DIFF_LINES:
        print(f"  … 多いため最初の {MAX_DIFF_LINES} 行までを表示（全体はHTML出力で確認できます）")

    if ask("\n左右に並べたHTML差分を書き出しますか？ (yes/no)", "no").lower() in ("yes", "y"):
        # ファイル名は固定にして、パスが長くなりすぎて書き出せない事故を避ける
        base = path_b.with_name("差分レポート.html")
        out = None
        for _ in range(5):
            cand = unique_path(base)
            if cand is None:
                break
            try:
                with open(cand, "x", encoding="utf-8") as f:
                    f.write(html_report(a_lines, b_lines, path_a.name, path_b.name))
                out = cand
                break
            except FileExistsError:
                continue
            except OSError as e:
                print(f"⚠ 書き出しに失敗しました: {e}")
                break
        if out is not None:
            print(f"✅ HTML差分を書き出しました（ブラウザで開けます）:\n   {out}")
        else:
            print("⚠ 別名ファイルを用意できず、書き出せませんでした。")

    pause_and_exit()


if __name__ == "__main__":
    main()
