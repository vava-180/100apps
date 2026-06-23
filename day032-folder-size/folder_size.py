# -*- coding: utf-8 -*-
"""
フォルダ容量レポートツール（Day 032）

指定したフォルダの直下にある「サブフォルダ」「ファイル」が、それぞれどれくらいの
容量かを調べ、大きい順に一覧表示します。「どこが容量を食っているか」がすぐ分かります。

しくみ:
  1) フォルダ直下の項目を1つずつ見る
  2) サブフォルダは中身をすべてたどって合計サイズを出す（ファイルはそのサイズ）
  3) 大きい順に並べて表示し、任意でCSVレポートに書き出す

外部ライブラリは使いません（標準ライブラリ os / pathlib のみ・ネット通信なし）。
このツールはファイルを移動・削除しません（読み取りだけ）。
使い方: ターミナルで  python folder_size.py   と実行するか、ファイルをダブルクリック。
"""

import csv
import os
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass


# ===== 中心ロジック（テストしやすい純粋関数）=====

def human_size(num_bytes: int) -> str:
    """バイト数を読みやすい単位にする（1024ごとに KB→MB→GB…と上げる、いわゆる1024基準）。"""
    units = ["B", "KB", "MB", "GB", "TB", "PB"]
    size = float(num_bytes)
    i = 0
    while size >= 1024 and i < len(units) - 1:
        size /= 1024
        i += 1
    if i == 0:
        return f"{int(num_bytes)} B"  # バイトは小数を付けない
    return f"{size:.1f} {units[i]}"


def dir_size(path: Path):
    """フォルダの中身をすべてたどって (合計バイト数, 読めず飛ばした数) を返す。

    シンボリックリンクはたどらない（無限ループや二重計算を避けるため）。
    リンク自身のサイズだけ数える。
    """
    total = 0
    skipped = 0

    def on_error(_e):
        nonlocal skipped
        skipped += 1  # フォルダをたどる途中の権限エラーなど

    for root, dirs, files in os.walk(path, onerror=on_error, followlinks=False):
        # フォルダへのリンクは os.walk が中へ潜らない（followlinks=False）。
        # ただし放置すると合計に入らないので、リンク自身のサイズだけここで足す。
        for name in dirs:
            dp = os.path.join(root, name)
            if os.path.islink(dp):
                try:
                    total += os.stat(dp, follow_symlinks=False).st_size
                except OSError:
                    skipped += 1
        for name in files:
            fp = os.path.join(root, name)
            try:
                # follow_symlinks=False で、リンク先ではなくリンク自身を見る
                total += os.stat(fp, follow_symlinks=False).st_size
            except OSError:
                skipped += 1
    return total, skipped


def entry_size(child: Path):
    """直下の1項目の (表示名, 種類, サイズ, 読めず飛ばした数) を返す。"""
    try:
        is_link = child.is_symlink()
    except OSError:
        is_link = False
    # リンクされたフォルダは中をたどらず、リンク自身のサイズだけにする
    # （先に is_link を確認し、リンクなら is_dir() でリンク先を見に行かせない）
    if not is_link and child.is_dir():
        size, skipped = dir_size(child)
        return child.name + "/", "フォルダ", size, skipped
    try:
        size = child.stat(follow_symlinks=False).st_size
        return child.name, ("リンク" if is_link else "ファイル"), size, 0
    except OSError:
        return child.name, "ファイル", 0, 1


def scan_folder(folder: Path):
    """直下の各項目を調べ、(項目リスト, 直下を読めず飛ばした数) を返す。

    項目は (表示名, 種類, サイズ, 中で飛ばした数) のタプル。サイズの大きい順に並べる。
    """
    entries = []
    listing_skipped = 0
    try:
        children = list(folder.iterdir())
    except OSError:
        return [], 1  # フォルダ自体が読めない
    for child in children:
        try:
            entries.append(entry_size(child))
        except OSError:
            listing_skipped += 1
    entries.sort(key=lambda e: e[2], reverse=True)  # サイズの大きい順
    return entries, listing_skipped


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


def write_report(path: Path, entries: list):
    """容量レポートをCSVに書き出す。Excelで開きやすい UTF-8（BOM付き）。"x"で上書きしない。"""
    with open(path, "x", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["名前", "種類", "サイズ(バイト)", "サイズ(読みやすい)"])
        for name, kind, size, _skipped in entries:
            writer.writerow([name, kind, size, human_size(size)])


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
    print(" フォルダ容量レポートツール（Day 032）")
    print("=" * 48)

    here = str(Path(__file__).parent)
    raw = ask("調べたいフォルダのパス", here)
    folder = Path(raw.strip('"'))
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    print("\n調べています…（サブフォルダの中までたどるので少し時間がかかります）")
    entries, listing_skipped = scan_folder(folder)
    if not entries:
        print("中身が空か、フォルダを読めませんでした。")
        pause_and_exit()
        return

    total = sum(e[2] for e in entries)
    inner_skipped = sum(e[3] for e in entries)

    print(f"\n--- 容量レポート（大きい順）/ 合計 {human_size(total)} ---")
    print(f"  {'サイズ':>12}  種類      名前")
    for name, kind, size, _sk in entries:
        print(f"  {human_size(size):>12}  {kind:<8}  {name}")

    if listing_skipped or inner_skipped:
        print(f"\n（読めずに飛ばした項目: 直下 {listing_skipped} 件 / 中身 {inner_skipped} 件）")

    if ask("\nこの結果をCSVレポートに書き出しますか？ (yes/no)", "no").lower() in ("yes", "y"):
        base = folder / "容量レポート.csv"
        out = None
        for _ in range(5):
            cand = unique_path(base)
            try:
                write_report(cand, entries)
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
