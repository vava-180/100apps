# -*- coding: utf-8 -*-
"""
フォルダ自動仕分けツール（Day 024）

散らかったフォルダの中のファイルを、サブフォルダに自動で仕分けします。
  1) 種類別：画像・文書・動画・音声・圧縮・その他 に分ける
  2) 拡張子別：jpg / pdf / xlsx … 拡張子ごとのフォルダに分ける
  3) 日付別：更新日の「年-月」フォルダに分ける（例 2026-06）

- 移動の前に必ずプレビューします
- 同じ名前があったら上書きせず、自動で連番を付けます

外部ライブラリは使いません（標準ライブラリのみ・ネット通信なし）。
使い方: ターミナルで  python organize.py   と実行するか、ファイルをダブルクリック。
"""

import sys
from datetime import datetime
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# 種類別に使う「拡張子 → フォルダ名」の対応
CATEGORY = {
    "画像": {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".heic", ".svg"},
    "文書": {".pdf", ".doc", ".docx", ".xls", ".xlsx", ".ppt", ".pptx", ".txt", ".csv", ".md"},
    "動画": {".mp4", ".mov", ".avi", ".mkv", ".wmv"},
    "音声": {".mp3", ".wav", ".m4a", ".aac", ".flac"},
    "圧縮": {".zip", ".rar", ".7z", ".tar", ".gz"},
}


# ===== 仕分け先を決める処理（画面表示と分けてテストできるようにする）=====

def category_of(ext: str) -> str:
    """拡張子から「種類フォルダ名」を返す。どれにも当てはまらなければ『その他』。"""
    ext = ext.lower()
    for name, exts in CATEGORY.items():
        if ext in exts:
            return name
    return "その他"


def folder_for(name: str, mode: str, mtime: float) -> str:
    """1つのファイルの「仕分け先フォルダ名」を返す。

    mode  : "category"(種類別) / "ext"(拡張子別) / "date"(日付別)
    mtime : 更新日時（date モードで使う・UNIX時間）
    """
    ext = Path(name).suffix.lower()
    if mode == "category":
        return category_of(ext)
    if mode == "ext":
        # 拡張子のドットを取って大文字に（.jpg → JPG）。拡張子なしは「拡張子なし」
        return ext[1:].upper() if ext else "拡張子なし"
    if mode == "date":
        return datetime.fromtimestamp(mtime).strftime("%Y-%m")
    return "その他"


def build_plan(files: list, mode: str) -> list:
    """[(ファイル名, 更新日時)] から [(ファイル名, 仕分け先フォルダ名)] を作る。"""
    return [(name, folder_for(name, mode, mtime)) for name, mtime in files]


def unique_destination(dest_dir: Path, name: str) -> Path:
    """移動先に同じ名前があれば、name(2).ext のように連番を付けて重複を避ける。"""
    target = dest_dir / name
    if not target.exists():
        return target
    stem, ext = Path(name).stem, Path(name).suffix
    i = 2
    while True:
        cand = dest_dir / f"{stem}({i}){ext}"
        if not cand.exists():
            return cand
        i += 1


# ===== 画面とのやり取り＆実行 =====

def ask(prompt: str, default: str = "") -> str:
    suffix = f"（未入力なら {default}）" if default else ""
    value = input(f"{prompt}{suffix}: ").strip()
    return value if value else default


def main():
    print("=" * 48)
    print(" フォルダ自動仕分けツール（Day 024）")
    print("=" * 48)

    here = Path(__file__).parent
    raw = ask("仕分けしたいフォルダのパス", str(here))
    folder = Path(raw)
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    self_name = Path(__file__).name
    # フォルダ直下のファイルだけ対象（サブフォルダ・隠しファイル・自分自身は除く）
    items = [p for p in folder.iterdir()
             if p.is_file() and not p.name.startswith(".") and p.name != self_name]
    if not items:
        print("仕分けるファイルがありません。")
        pause_and_exit()
        return

    print("\nどの方法で仕分けますか？")
    print("  1) 種類別（画像・文書・動画 …）")
    print("  2) 拡張子別（JPG / PDF / XLSX …）")
    print("  3) 日付別（更新日の年-月）")
    choice = ask("番号を選ぶ", "1")
    mode = {"1": "category", "2": "ext", "3": "date"}.get(choice)
    if mode is None:
        print("⚠ 番号が正しくありません。中止します。")
        pause_and_exit()
        return

    files = [(p.name, p.stat().st_mtime) for p in items]
    plan = build_plan(files, mode)

    # フォルダごとに何件入るかを集計してプレビュー
    print("\n--- 仕分けプレビュー（まだ移動していません）---")
    summary = {}
    for _, dest in plan:
        summary[dest] = summary.get(dest, 0) + 1
    for dest in sorted(summary):
        print(f"  [{dest}] フォルダへ … {summary[dest]} 件")
    print(f"--- 合計 {len(plan)} 件を移動します ---")

    answer = ask("\n本当に実行しますか？ (yes/no)", "no")
    if answer.lower() not in ("yes", "y"):
        print("中止しました。ファイルは移動していません。")
        pause_and_exit()
        return

    moved_log = []  # (元の名前, 移動先) … 途中で失敗したとき、どこへ行ったか分かるように残す
    try:
        for name, dest in plan:
            dest_dir = folder / dest
            dest_dir.mkdir(exist_ok=True)
            target = unique_destination(dest_dir, name)
            (folder / name).rename(target)
            moved_log.append((name, f"{dest}/{target.name}"))
    except OSError as e:
        print(f"⚠ 移動中にエラーが起きました（{len(moved_log)}件まで移動済み）: {e}")
        if moved_log:
            print("  すでに移動したファイル（手で戻せます）:")
            for src, dst in moved_log:
                print(f"    {src}  →  {dst}")
        pause_and_exit()
        return

    print(f"\n✅ 完了しました。{len(moved_log)} 件を仕分けました。")
    pause_and_exit()


def pause_and_exit():
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass


if __name__ == "__main__":
    main()
