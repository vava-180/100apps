# -*- coding: utf-8 -*-
"""
PDF結合・分割ツール（Day 023）

PDFをまとめたり、分けたりする実務ツールです。
  1) 結合：フォルダ内の複数PDFを1つにまとめる
  2) 分割：1つのPDFを1ページずつバラバラのPDFにする
  3) 抜き出し：指定したページ範囲だけを取り出して新しいPDFにする

PDFの読み書きには pypdf ライブラリを使います（ローカルで動作・ネット通信なし）。
事前に1回だけ:  pip install pypdf
使い方: ターミナルで  python pdf_tool.py   と実行するか、ファイルをダブルクリック。
"""

import re
import sys
from pathlib import Path

# Windowsのコンソールで表示できない文字が混じっても止まらないようにする
try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# pypdf が無い場合は、入れ方を案内して終了する
try:
    from pypdf import PdfReader, PdfWriter
except ImportError:
    print("このツールには pypdf が必要です。次のコマンドで一度だけ入れてください:")
    print("    pip install pypdf")
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass
    sys.exit(1)


# ===== ページ範囲を解釈する処理（画面表示と分けてテストできるようにする）=====

def parse_pages(text: str, total: int) -> list:
    """"1-3,5,8" のような指定を、0始まりのページ番号リストに変換する。

    text  : ユーザーが入れた範囲指定（1始まりで分かりやすく）
    total : PDFの総ページ数
    戻り値: 取り出すページ番号（0始まり）のリスト。順番・指定どおり、重複は残す。
    エラーがあれば ValueError を投げる。
    """
    pages = []
    for part in text.split(","):
        part = part.strip()
        if not part:
            continue
        # 「数字」または「数字-数字」の形だけ許可（-1 や 1- や a などを弾く）
        if not re.fullmatch(r"\d+(-\d+)?", part):
            raise ValueError(f"ページの指定が正しくありません（例: 1-3,5 の形）: {part}")
        if "-" in part:
            a, b = part.split("-", 1)
            start, end = int(a), int(b)
            if start < 1 or end < 1 or start > end:
                raise ValueError(f"範囲の指定がおかしいです: {part}")
            for n in range(start, end + 1):
                if n > total:
                    raise ValueError(f"{n}ページ目はありません（全{total}ページ）")
                pages.append(n - 1)
        else:
            n = int(part)
            if n < 1 or n > total:
                raise ValueError(f"{n}ページ目はありません（全{total}ページ）")
            pages.append(n - 1)
    if not pages:
        raise ValueError("ページが1つも指定されていません")
    return pages


# ===== PDFの読み書き =====

def open_pdf(path: Path):
    """PDFを開く。パスワードなしで開けない場合は None を返す。"""
    reader = PdfReader(str(path))
    if reader.is_encrypted:
        # 空パスワードでの解除だけ試す（パスワード付きは対象外）
        try:
            if reader.decrypt("") == 0:
                return None
        except Exception:
            return None
    return reader


def save_pdf(writer: PdfWriter, path: Path):
    with open(path, "wb") as f:
        writer.write(f)


def unique_path(path: Path) -> Path:
    """同名ファイルがあれば name(2).ext のように連番を付ける（上書きを防ぐ）。"""
    if not path.exists():
        return path
    stem, ext, parent = path.stem, path.suffix, path.parent
    i = 2
    while True:
        cand = parent / f"{stem}({i}){ext}"
        if not cand.exists():
            return cand
        i += 1


def unique_dir(path: Path) -> Path:
    """同名フォルダがあれば name(2) のように連番を付ける。"""
    if not path.exists():
        return path
    i = 2
    while True:
        cand = path.parent / f"{path.name}({i})"
        if not cand.exists():
            return cand
        i += 1


def merge(folder: Path, out_path: Path) -> int:
    """フォルダ内のPDFを名前順にまとめて1つにする。まとめたページ数を返す。"""
    # このツールが作った出力ファイル（merged～ / ～_extract）は、混ざらないよう除外する
    pdfs = sorted([p for p in folder.iterdir()
                   if p.is_file() and p.suffix.lower() == ".pdf" and p != out_path
                   and not p.name.lower().startswith("merged")
                   and not p.stem.lower().endswith("_extract")])
    if len(pdfs) < 2:
        print("結合するには、PDFが2つ以上必要です。")
        return 0

    print(f"\n結合するPDF（この順番）: {len(pdfs)} 件")
    for p in pdfs:
        print(f"  - {p.name}")

    writer = PdfWriter()
    total = 0
    for p in pdfs:
        # 壊れたPDFが1つあっても全体を止めず、そのファイルだけ飛ばす
        try:
            reader = open_pdf(p)
        except Exception as e:
            print(f"  ⚠ 読めないため飛ばします: {p.name}（{e}）")
            continue
        if reader is None:
            print(f"  ⚠ パスワード付きのため飛ばします: {p.name}")
            continue
        try:
            for page in reader.pages:
                writer.add_page(page)
                total += 1
        except Exception as e:
            print(f"  ⚠ 取り込み中に問題があり飛ばします: {p.name}（{e}）")

    if total == 0:
        print("まとめられるページがありませんでした。")
        return 0
    save_pdf(writer, out_path)
    return total


def split(path: Path, out_dir: Path) -> int:
    """PDFを1ページずつ別ファイルにする。作ったファイル数を返す。"""
    reader = open_pdf(path)
    if reader is None:
        print("パスワード付きPDFは分割できません。")
        return 0
    out_dir.mkdir(exist_ok=True)
    count = len(reader.pages)
    digits = len(str(count))  # ページ番号の桁数（10ページなら2桁）
    stem = path.stem
    for i, page in enumerate(reader.pages, start=1):
        writer = PdfWriter()
        writer.add_page(page)
        save_pdf(writer, out_dir / f"{stem}_p{str(i).zfill(digits)}.pdf")
    return count


def extract(path: Path, pages_text: str, out_path: Path) -> int:
    """指定ページ範囲だけを取り出して新しいPDFにする。取り出したページ数を返す。"""
    reader = open_pdf(path)
    if reader is None:
        print("パスワード付きPDFは処理できません。")
        return 0
    total = len(reader.pages)
    page_indexes = parse_pages(pages_text, total)  # ValueErrorはmain側で受ける
    writer = PdfWriter()
    for idx in page_indexes:
        writer.add_page(reader.pages[idx])
    save_pdf(writer, out_path)
    return len(page_indexes)


# ===== 画面とのやり取り =====

def ask(prompt: str, default: str = "") -> str:
    suffix = f"（未入力なら {default}）" if default else ""
    value = input(f"{prompt}{suffix}: ").strip()
    return value if value else default


def choose_pdf(folder: Path):
    """フォルダ内のPDFを一覧から1つ選ぶ。"""
    pdfs = sorted([p for p in folder.iterdir() if p.is_file() and p.suffix.lower() == ".pdf"])
    if not pdfs:
        print("PDFが見つかりませんでした。")
        return None
    print("\nどのPDFを使いますか？")
    for i, p in enumerate(pdfs, start=1):
        print(f"  {i}) {p.name}")
    raw = ask("番号を選ぶ", "1")
    try:
        return pdfs[int(raw) - 1]
    except (ValueError, IndexError):
        print("⚠ 番号が正しくありません。")
        return None


def main():
    print("=" * 48)
    print(" PDF結合・分割ツール（Day 023）")
    print("=" * 48)

    here = Path(__file__).parent
    raw = ask("PDFが入っているフォルダのパス", str(here))
    folder = Path(raw)
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    print("\n何をしますか？")
    print("  1) 結合（複数PDF → 1つ）")
    print("  2) 分割（1つのPDF → 1ページずつ）")
    print("  3) 抜き出し（指定ページだけ取り出す）")
    choice = ask("番号を選ぶ", "1")

    try:
        if choice == "1":
            out_path = unique_path(folder / "merged.pdf")
            n = merge(folder, out_path)
            if n:
                print(f"\n✅ 完了しました: {out_path}（全{n}ページ）")

        elif choice == "2":
            target = choose_pdf(folder)
            if target is None:
                pause_and_exit()
                return
            out_dir = unique_dir(folder / f"{target.stem}_split")
            n = split(target, out_dir)
            if n:
                print(f"\n✅ 完了しました: {out_dir} に {n} ファイル")

        elif choice == "3":
            target = choose_pdf(folder)
            if target is None:
                pause_and_exit()
                return
            reader = open_pdf(target)
            if reader is None:
                print("パスワード付きPDFは処理できません。")
                pause_and_exit()
                return
            total = len(reader.pages)
            print(f"このPDFは全 {total} ページです。")
            pages_text = ask("取り出すページ（例: 1-3,5）")
            out_path = folder / f"{target.stem}_extract.pdf"
            n = extract(target, pages_text, out_path)
            if n:
                print(f"\n✅ 完了しました: {out_path}（{n}ページ）")
        else:
            print("⚠ 番号が正しくありません。")
    except ValueError as e:
        print(f"⚠ {e}")
    except Exception as e:
        # 壊れたPDFなどで失敗しても、初心者に分かるメッセージで止める
        print(f"⚠ 処理中にエラーが起きました: {e}")

    pause_and_exit()


def pause_and_exit():
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass


if __name__ == "__main__":
    main()
