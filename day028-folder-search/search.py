# -*- coding: utf-8 -*-
"""
フォルダ内 横断検索ツール（Day 028）

指定したフォルダの中を、ファイル名と中身（テキスト）の両方からキーワードで検索します。
中身が当たった場合は「何行目のどの行か」も表示するので、目的の箇所をすぐ探せます。

しくみ:
  1) フォルダ内のファイルを集める（サブフォルダも対象にできる）
  2) ファイル名にキーワードが含まれるかを調べる
  3) テキストとして読めるファイルは、中身も1行ずつ調べる（読めないものは中身検索を飛ばす）
文字コードは UTF-8 と Shift_JIS(cp932) を自動で判別します。

外部ライブラリは使いません（標準ライブラリのみ・ネット通信なし）。
使い方: ターミナルで  python search.py   と実行するか、ファイルをダブルクリック。
"""

import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# 1ファイルあたり、表示する中身ヒットの上限（多すぎる時に画面が埋まらないように）
MAX_HITS_PER_FILE = 50
# 中身検索する1ファイルの大きさの上限（これより大きいファイルは中身検索しない）
MAX_CONTENT_BYTES = 20 * 1024 * 1024  # 20MB


# ===== 検索の中心ロジック（ファイル不要・テストしやすい純粋関数）=====

def contains(text: str, keyword: str, case_sensitive: bool) -> bool:
    """text の中に keyword が含まれるか（大文字小文字の区別は選べる）。"""
    if keyword == "":
        return False
    if case_sensitive:
        return keyword in text
    # casefold は lower より広く大文字小文字をそろえる（多言語でも自然に一致）
    return keyword.casefold() in text.casefold()


def find_in_text(text: str, keyword: str, case_sensitive: bool, limit: int) -> list:
    """中身からキーワードを探し、[(行番号, その行の文字列), ...] を返す（最大 limit 件）。

    行はインデント（先頭の空白）も情報なので、改行だけ取り除いてそのまま返す。
    """
    hits = []
    for i, line in enumerate(text.splitlines(), start=1):
        if contains(line, keyword, case_sensitive):
            hits.append((i, line))
            if len(hits) >= limit:
                break
    return hits


# ===== ファイルの読み取り =====

def read_text(path: Path):
    """テキストとして読む。UTF-8→Shift_JIS の順に試す。読めなければ None（＝中身検索の対象外）。
    大きすぎるファイル（動画やDBなど）は、メモリを食うので中身検索しない。"""
    try:
        if path.stat().st_size > MAX_CONTENT_BYTES:
            return None
        raw = path.read_bytes()
    except OSError:
        return None
    # 中身にヌル文字がある＝画像などのバイナリとみなして中身検索しない
    if b"\x00" in raw:
        return None
    for enc in ("utf-8-sig", "cp932"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return None


def collect_files(folder: Path, recursive: bool, exts: list, self_path: Path):
    """対象ファイルを集める。(ファイル一覧, 読めず飛ばした数) を返す。

    除くもの: 「.」で始まる隠しファイル／隠しフォルダの中身・自分自身（このスクリプト）。
    権限エラーや壊れたリンクが混ざっても、そのファイルだけ飛ばして全体は止めない。
    """
    self_resolved = self_path.resolve()
    it = folder.rglob("*") if recursive else folder.iterdir()
    files = []
    skipped = 0
    while True:
        try:
            p = next(it)
        except StopIteration:
            break
        except OSError:
            skipped += 1   # フォルダをたどる途中での権限エラーなど
            continue
        try:
            if not p.is_file():
                continue
            # パスの途中に隠しフォルダ（.git や .claude など）があれば、その中身は対象外
            if any(part.startswith(".") for part in p.relative_to(folder).parts):
                continue
            if p.resolve() == self_resolved:  # 同名ファイルが別フォルダにあっても、本物の自分だけ除く
                continue
            if exts and p.suffix.lower() not in exts:
                continue
            files.append(p)
        except OSError:
            skipped += 1   # この1ファイルの情報が取れない（権限・壊れリンクなど）
            continue
    return files, skipped


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
    print(" フォルダ内 横断検索ツール（Day 028）")
    print("=" * 48)

    here = Path(__file__).parent
    raw = ask("検索するフォルダのパス", str(here))
    folder = Path(raw.strip('"'))
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    keyword = ask("検索キーワード", "")
    if keyword == "":
        print("⚠ キーワードが空です。")
        pause_and_exit()
        return

    target = ask("検索対象: 1) 名前と中身  2) 名前だけ  3) 中身だけ", "1").strip()
    if target not in ("1", "2", "3"):
        print("⚠ 1〜3 の番号で選んでください。")
        pause_and_exit()
        return
    search_name = target in ("1", "2")
    search_body = target in ("1", "3")

    exts = normalize_exts(ask("対象の拡張子（カンマ区切り。空Enterで全ファイル）", ""))
    recursive = ask("サブフォルダの中も検索しますか？ (yes/no)", "yes").lower() in ("yes", "y")
    case_sensitive = ask("大文字小文字を区別しますか？ (yes/no)", "no").lower() in ("yes", "y")

    files, skipped = collect_files(folder, recursive, exts, Path(__file__))
    if skipped:
        print(f"（権限エラーなどで {skipped} 件のパスを飛ばしました）")
    if not files:
        print("対象ファイルが見つかりませんでした。")
        pause_and_exit()
        return

    print(f"\n{len(files)} 件を検索しています…\n")
    name_hits = 0   # 名前が当たったファイル数
    body_files = 0  # 中身が当たったファイル数
    body_lines = 0  # 中身が当たった行の合計

    for p in sorted(files, key=lambda x: str(x)):
        rel = p.relative_to(folder)
        # 1) ファイル名
        if search_name and contains(p.name, keyword, case_sensitive):
            print(f"[名前] {rel}")
            name_hits += 1
        # 2) 中身
        if search_body:
            text = read_text(p)
            if text is None:
                continue  # 読めない／バイナリは中身検索の対象外
            hits = find_in_text(text, keyword, case_sensitive, MAX_HITS_PER_FILE)
            if hits:
                body_files += 1
                body_lines += len(hits)
                print(f"[中身] {rel}")
                for lineno, line in hits:
                    print(f"        {lineno:>5}: {line}")
                if len(hits) >= MAX_HITS_PER_FILE:
                    print(f"        … 多いため最初の {MAX_HITS_PER_FILE} 行までを表示")

    print("\n" + "-" * 48)
    if name_hits == 0 and body_files == 0:
        print(f"『{keyword}』は見つかりませんでした。")
    else:
        parts = []
        if search_name:
            parts.append(f"名前ヒット {name_hits} 件")
        if search_body:
            parts.append(f"中身ヒット {body_files} ファイル（{body_lines} 行）")
        print("結果: " + " / ".join(parts))
    pause_and_exit()


if __name__ == "__main__":
    main()
