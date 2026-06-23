# -*- coding: utf-8 -*-
"""
テキスト一括置換ツール（Day 027）

フォルダの中の複数テキストファイルから、指定した文字をまとめて別の文字に置き換えます。
いきなり書き換えず、まず「どのファイルで何件置き換わるか」をプレビューし、yesで実行します。
安全のため、書き換える前に元ファイルの控え（.bak）を残せます（任意）。

しくみ:
  1) 対象フォルダ内の、指定した拡張子のテキストファイルを集める
  2) 各ファイルを読み、置換件数を数える（プレビュー）
  3) yesなら置換して保存（無変更のファイルは触らない）
文字コードは UTF-8 と Shift_JIS(cp932) を自動で判別し、どちらでも読めないものは飛ばします。

外部ライブラリは使いません（標準ライブラリ re / shutil のみ・ネット通信なし）。
使い方: ターミナルで  python replace_text.py   と実行するか、ファイルをダブルクリック。
"""

import re
import shutil
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass


# ===== 置換の中心ロジック（ファイル不要・テストしやすい純粋関数）=====

def replace_in_text(text: str, search: str, replace: str, case_sensitive: bool):
    """文字列の中の search を replace に置き換える。(新しい文字列, 置換件数) を返す。

    case_sensitive=False なら大文字小文字を区別せずに置き換える。
    search は正規表現ではなく「ただの文字」として扱う（re.escape で記号も安全に）。
    """
    if search == "":
        return text, 0
    flags = 0 if case_sensitive else re.IGNORECASE
    pattern = re.compile(re.escape(search), flags)
    new_text, count = pattern.subn(lambda _m: replace, text)
    return new_text, count


def normalize_exts(raw: str) -> list:
    """「.txt, md ,.csv」のような入力を ['.txt', '.md', '.csv'] に整える。"""
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


# ===== ファイルの読み書き =====

def read_text(path: Path):
    """テキストを読む。(本文, 書き戻し用の文字コード名) を返す。読めなければ (None, None)。

    返す文字コードは「書き戻すときに元の形を保てる」ものにする:
      - 先頭にBOM付きUTF-8 → 'utf-8-sig'（書き戻しでもBOMを付け直す）
      - BOM無しUTF-8       → 'utf-8'（よけいなBOMを足さない）
      - Shift_JIS          → 'cp932'
    """
    try:
        raw = path.read_bytes()
    except OSError:
        return None, None
    if raw.startswith(b"\xef\xbb\xbf"):  # BOM付きUTF-8
        # BOMは強い目印。BOM付きなのにUTF-8として読めない＝壊れている可能性が高いので、
        # cp932にフォールバックせず対象外にする（誤判定で中身を壊さないため）
        try:
            return raw.decode("utf-8-sig"), "utf-8-sig"
        except UnicodeDecodeError:
            return None, None
    for enc in ("utf-8", "cp932"):
        try:
            return raw.decode(enc), enc
        except UnicodeDecodeError:
            continue
    return None, None


def is_backup_name(name: str) -> bool:
    """このツールが作る控えファイル（.bak / .bak2 / .bak3 …）かどうか。"""
    return re.search(r"\.bak\d*$", name, re.IGNORECASE) is not None


def collect_files(folder: Path, recursive: bool, exts: list, self_path: Path) -> list:
    """対象ファイルを集める。隠しファイル・自分自身・控え(.bak系)は除く。"""
    it = folder.rglob("*") if recursive else folder.iterdir()
    self_resolved = self_path.resolve()
    files = []
    for p in it:
        if not p.is_file() or p.name.startswith("."):
            continue
        if p.resolve() == self_resolved:  # 自分自身（このスクリプト）だけを確実に除く
            continue
        if is_backup_name(p.name):
            continue
        if exts and p.suffix.lower() not in exts:
            continue
        files.append(p)
    return files


def write_bytes_atomic(path: Path, data: bytes):
    """同じフォルダに一時ファイルを書いてから置き換える。書き込み途中で失敗しても元ファイルを壊さない。"""
    tmp = path.with_name(path.name + ".tmp_replace")
    try:
        tmp.write_bytes(data)
        tmp.replace(path)  # 置き換えは最後の一瞬だけ。成功した時だけ新しい中身になる
    except OSError:
        try:
            if tmp.exists():
                tmp.unlink()
        except OSError:
            pass
        raise


def backup_path(path: Path) -> Path:
    """控え(.bak)の保存先。既にあれば連番を付けて上書きしない。"""
    cand = path.with_suffix(path.suffix + ".bak")
    if not cand.exists():
        return cand
    i = 2
    while True:
        c = path.with_suffix(path.suffix + f".bak{i}")
        if not c.exists():
            return c
        i += 1


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
    print(" テキスト一括置換ツール（Day 027）")
    print("=" * 48)

    here = Path(__file__).parent
    raw = ask("置換したいフォルダのパス", str(here))
    folder = Path(raw.strip('"'))
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    search = ask("探す文字（置換される前の文字）", "")
    if search == "":
        print("⚠ 探す文字が空です。")
        pause_and_exit()
        return
    # 置換後は空でもよい（＝その文字を削除する、という意味になる）
    replace = ask("置き換える文字（空Enterなら削除）", "")

    exts = normalize_exts(ask("対象の拡張子（カンマ区切り。空Enterで .txt,.md,.csv）", ".txt,.md,.csv"))
    recursive = ask("サブフォルダの中も対象にしますか？ (yes/no)", "no").lower() in ("yes", "y")
    case_sensitive = ask("大文字小文字を区別しますか？ (yes/no)", "no").lower() in ("yes", "y")

    files = collect_files(folder, recursive, exts, Path(__file__))
    if not files:
        print("対象ファイルが見つかりませんでした。")
        pause_and_exit()
        return

    # --- プレビュー：読みながら置換件数を数える（まだ書き換えない）---
    print(f"\n{len(files)} 件を確認しています…")
    plan = []          # (path, encoding, count) … 1件以上置換があるものだけ
    skipped = []       # 読めなかったファイル
    cant_save = []     # 置換後の文字を、元の文字コードでは保存できないファイル
    total = 0
    for p in files:
        text, enc = read_text(p)
        if text is None:
            skipped.append(p)
            continue
        new, count = replace_in_text(text, search, replace, case_sensitive)
        if count == 0:
            continue
        # 置換後の文字を「元の文字コード」で保存できるか、ここで試して確かめる
        # （例: cp932のファイルに、cp932で表せない文字を入れようとするとエラー）
        try:
            new.encode(enc)
        except UnicodeEncodeError:
            cant_save.append(p)
            continue
        plan.append((p, enc, count))
        total += count

    if skipped:
        print("⚠ 読めずに飛ばしたファイル:")
        for p in skipped:
            print(f"   {p.relative_to(folder)}")
    if cant_save:
        print("⚠ 置換後の文字を元の文字コードで保存できないため飛ばすファイル:")
        for p in cant_save:
            print(f"   {p.relative_to(folder)}")

    if not plan:
        print(f"\n『{search}』の置換対象はありませんでした。")
        pause_and_exit()
        return

    print(f"\n--- 置換プレビュー（合計 {total} 件 / {len(plan)} ファイル）---")
    for p, _enc, count in plan:
        print(f"   {count:>4} 件: {p.relative_to(folder)}")

    print(f"\n『{search}』→『{replace}』に置き換えます。")
    make_backup = ask("置換前に控え(.bak)を残しますか？ (yes/no)", "yes").lower() in ("yes", "y")
    if ask("実行しますか？ (yes/no)", "no").lower() not in ("yes", "y"):
        print("実行しませんでした。プレビューのみです。")
        pause_and_exit()
        return

    # --- 実行：1ファイルずつ控え→置換→保存。途中で失敗しても、それまでの結果は残す ---
    done = 0
    changed = []  # プレビュー後に中身が変わって件数が合わなくなったファイル
    for p, enc, planned_count in plan:
        try:
            text, _ = read_text(p)
            if text is None:
                continue  # プレビュー後に読めなくなった場合は飛ばす
            new_text, actual = replace_in_text(text, search, replace, case_sensitive)
            if actual != planned_count:
                changed.append(p)  # プレビュー時と件数が違う＝外部で変更された可能性。安全のため飛ばす
                continue
            data = new_text.encode(enc)  # 文字コードを保ち、改行も変えない（バイトで書く）
            if make_backup:
                shutil.copy2(p, backup_path(p))
            write_bytes_atomic(p, data)
            done += 1
        except (OSError, UnicodeError) as e:
            print(f"⚠ 失敗（飛ばしました）: {p.relative_to(folder)} … {e}")

    print(f"\n✅ 完了しました。{done} / {len(plan)} ファイルを置換しました。")
    if changed:
        print("⚠ プレビュー後に内容が変わったため飛ばしたファイル:")
        for p in changed:
            print(f"   {p.relative_to(folder)}")
    if make_backup:
        print("   置換前の控えは、各ファイルと同じ場所に .bak で残しています。")
    pause_and_exit()


if __name__ == "__main__":
    main()
