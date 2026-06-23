# -*- coding: utf-8 -*-
"""
PDFテキスト抽出ツール（Day 038）

PDFファイルから文字（テキスト）を取り出して、.txt ファイルに保存します。
1つのPDFでも、フォルダの中の複数PDFでもまとめて処理できます。

しくみ:
  1) PDFファイル、またはPDFが入ったフォルダを指定する
  2) 各PDFをページごとに読み、文字を取り出す
  3) 『元の名前.txt』として書き出す（ページの区切りも入れる）
パスワード付きPDFや、文字が画像になっているPDF（スキャン画像など）は
取り出せないことがあります（その場合は飛ばす／空になる）。

外部ライブラリは pypdf を使います（PDFをローカルで読むためのもの・ネット通信なし）。
  インストール（1回だけ）:  python -m pip install pypdf
元のPDFは書き換えません（読み取り＋txtの書き出しだけ）。
フォルダ指定のときは、その直下のPDFだけが対象です（サブフォルダの中は見ません）。
使い方: ターミナルで  python extract_text.py   と実行するか、ファイルをダブルクリック。
"""

import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

try:
    from pypdf import PdfReader
except ImportError:
    print("pypdf が見つかりません。先に  python -m pip install pypdf  を実行してください。")
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass
    sys.exit(1)


# ===== 中心ロジック =====

def page_separator(page_no: int) -> str:
    """ページの区切り（何ページ目かが分かる見出し）。"""
    return f"\n\n----- ページ {page_no} -----\n"


def extract_pdf_text(path: Path):
    """PDFから全ページのテキストを取り出す。(本文, ページ数, エラー文) を返す。

    成功時エラー文=None。暗号化で開けない／壊れている場合はエラー文を返す。
    """
    try:
        reader = PdfReader(path)
    except Exception as e:  # pypdf は壊れたPDFで様々な例外を出すので広めに受ける
        return None, 0, f"PDFを開けません（壊れている可能性）: {e}"

    if reader.is_encrypted:
        # パスワード無し（空）で開けるか試す。だめなら対象外
        try:
            if reader.decrypt("") == 0:
                return None, 0, "パスワード付きPDFのため開けません。"
        except Exception:
            return None, 0, "パスワード付きPDFのため開けません。"

    # ページ数の取得。暗号化や破損だと、ここで失敗することがある
    try:
        page_count = len(reader.pages)
    except Exception as e:
        if reader.is_encrypted:
            return None, 0, "パスワード付きPDFのため開けません。"
        return None, 0, f"PDFの構造を読めません（壊れている可能性）: {e}"

    parts = []
    has_text = False   # 1ページでも実際に文字が取れたか
    failed = 0         # 読み取りに失敗したページ数
    for i in range(page_count):
        page_no = i + 1
        try:
            text = reader.pages[i].extract_text() or ""
        except Exception:
            # 1ページ壊れていても、そのページだけ飛ばして次へ進む（ページ単位処理）
            failed += 1
            parts.append(page_separator(page_no) + f"[ページ {page_no}: 読み取り失敗]")
            continue
        if text.strip():
            has_text = True
        parts.append(page_separator(page_no) + text)

    if not has_text:
        if failed:
            return None, 0, "全ページの読み取りに失敗しました（壊れている可能性）。"
        # 文字が1つも取れない＝画像PDF（スキャン画像）など。txtは作らせない
        return "", page_count, None
    return "".join(parts).strip(), page_count, None


def collect_pdfs(folder: Path):
    """フォルダ直下のPDFを集める（名前順）。"""
    return sorted(
        p for p in folder.iterdir()
        if p.is_file() and p.suffix.lower() == ".pdf")


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


def save_text(pdf_path: Path, body: str):
    """抽出テキストを『元の名前.txt』として書き出す。書き出したPathを返す（失敗時None）。"""
    base = pdf_path.with_suffix(".txt")
    for _ in range(5):  # 直前に同名ができても別名でやり直す
        out = unique_path(base)
        if out is None:
            return None
        try:
            with open(out, "x", encoding="utf-8") as f:
                f.write(body)
            return out
        except FileExistsError:
            continue
        except OSError as e:
            print(f"⚠ 書き出しに失敗しました: {e}")
            return None
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


def process_one(pdf: Path):
    """1つのPDFを処理して結果を表示する。"""
    body, pages, error = extract_pdf_text(pdf)
    if error is not None:
        print(f"⚠ {pdf.name}: {error}")
        return
    if not body:
        print(f"△ {pdf.name}: 文字を取り出せませんでした（画像PDFの可能性。{pages}ページ）。")
        return
    out = save_text(pdf, body)
    if out is None:
        print(f"⚠ {pdf.name}: 書き出し先を用意できませんでした。")
        return
    print(f"✅ {pdf.name}（{pages}ページ） → {out.name}")


def main():
    print("=" * 48)
    print(" PDFテキスト抽出ツール（Day 038）")
    print("=" * 48)

    raw = ask("PDFファイル、またはPDFが入ったフォルダのパス", "")
    if raw == "":
        print("⚠ パスが空です。")
        pause_and_exit()
        return
    target = Path(raw.strip().strip('"').strip("'"))  # コピペの引用符（"や'）を取り除く

    if target.is_file():
        if target.suffix.lower() != ".pdf":
            print("⚠ PDFファイルを指定してください。")
            pause_and_exit()
            return
        process_one(target)
    elif target.is_dir():
        pdfs = collect_pdfs(target)
        if not pdfs:
            print("フォルダの中にPDFが見つかりませんでした。")
            pause_and_exit()
            return
        print(f"\n{len(pdfs)} 個のPDFを処理します（サブフォルダは対象外）…\n")
        for pdf in pdfs:
            process_one(pdf)
    else:
        print(f"⚠ 見つかりません: {target}")

    pause_and_exit()


if __name__ == "__main__":
    main()
