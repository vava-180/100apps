# -*- coding: utf-8 -*-
"""
重複ファイル検出ツール（Day 025）

フォルダの中から「中身がまったく同じファイル」を見つけます。
名前がちがっても、中身が同じならコピー（重複）として検出します。

しくみ:
  1) まずファイルサイズで仲間分け（サイズがちがえば中身もちがう）
  2) 同じサイズのものだけ、内容のハッシュ（SHA-256）で本当に同じか確認
見つけた重複は一覧表示し、希望すれば「1つだけ残して、残りを _duplicates フォルダへ移動」します
（いきなり削除はしません。安全のため移動です）。

外部ライブラリは使いません（標準ライブラリ hashlib のみ・ネット通信なし）。
使い方: ターミナルで  python find_dup.py   と実行するか、ファイルをダブルクリック。
"""

import csv
import hashlib
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass


# ===== 重複を見つける中心の処理（テストしやすいよう、サイズ取得・ハッシュ計算は外から渡す）=====

def find_duplicate_groups(paths: list, size_of, hash_of) -> list:
    """中身が同じファイルのグループ（2つ以上）の一覧を返す。

    paths   : 対象ファイルのパス一覧
    size_of : path → ファイルサイズ を返す関数
    hash_of : path → 内容ハッシュ を返す関数（サイズが同じ時だけ呼ぶ）
    戻り値  : [[同じ中身のpath, ...], ...]
    """
    # 1) サイズごとにまとめる（サイズが取れない＝Noneのものは飛ばす）
    by_size = {}
    for p in paths:
        size = size_of(p)
        if size is None:
            continue
        by_size.setdefault(size, []).append(p)

    groups = []
    for size, same_size in by_size.items():
        if len(same_size) < 2:
            continue  # サイズが唯一なら重複なし（ハッシュ計算を省ける）
        # 2) 同じサイズの中だけ、ハッシュでまとめる（ハッシュが取れないものは飛ばす）
        by_hash = {}
        for p in same_size:
            h = hash_of(p)
            if h is None:
                continue
            by_hash.setdefault(h, []).append(p)
        for h, same in by_hash.items():
            if len(same) >= 2:
                groups.append(same)
    return groups


# ===== ファイル操作 =====

def file_hash(path: Path) -> str:
    """ファイルの内容からSHA-256ハッシュを計算する。大きなファイルも少しずつ読む。"""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def collect_files(folder: Path, recursive: bool, self_name: str) -> list:
    """対象ファイルを集める。隠しファイル・自分自身・前回の _duplicates の中は除く。"""
    it = folder.rglob("*") if recursive else folder.iterdir()
    files = []
    for p in it:
        if not p.is_file() or p.name.startswith(".") or p.name == self_name:
            continue
        # 前回この機能で移動した _duplicates フォルダの中は調べない（再移動を防ぐ）
        if "_duplicates" in p.relative_to(folder).parts:
            continue
        files.append(p)
    return files


def unique_destination(dest_dir: Path, name: str) -> Path:
    """移動先に同名があれば連番を付けて重複を避ける。"""
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


def human_size(n: int) -> str:
    """バイト数を読みやすい単位にする（例: 2048 → 2.0 KB）。"""
    units = ["B", "KB", "MB", "GB", "TB"]
    size = float(n)
    for u in units:
        if size < 1024 or u == units[-1]:
            return f"{int(size)} {u}" if u == "B" else f"{size:.1f} {u}"
        size /= 1024
    return f"{n} B"


# ===== 画面とのやり取り =====

def ask(prompt: str, default: str = "") -> str:
    suffix = f"（未入力なら {default}）" if default else ""
    value = input(f"{prompt}{suffix}: ").strip()
    return value if value else default


def main():
    print("=" * 48)
    print(" 重複ファイル検出ツール（Day 025）")
    print("=" * 48)

    here = Path(__file__).parent
    raw = ask("調べたいフォルダのパス", str(here))
    folder = Path(raw)
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    recursive = ask("サブフォルダの中も調べますか？ (yes/no)", "no").lower() in ("yes", "y")
    self_name = Path(__file__).name
    files = collect_files(folder, recursive, self_name)
    if len(files) < 2:
        print("調べるファイルが足りません。")
        pause_and_exit()
        return

    print(f"\n{len(files)} 件を調べています…")
    # 読み取れないファイルがあっても全体を止めず、そのファイルだけ飛ばして最後に報告する
    failures = []

    def safe_size(p):
        try:
            return p.stat().st_size
        except OSError:
            failures.append(p)
            return None

    def safe_hash(p):
        try:
            return file_hash(p)
        except OSError:
            failures.append(p)
            return None

    groups = find_duplicate_groups(files, safe_size, safe_hash)
    if failures:
        print("⚠ 読み取れず調べられなかったファイル:")
        for p in sorted(set(failures), key=lambda x: str(x)):
            print(f"   {p.relative_to(folder)}")

    if not groups:
        print("\n✅ 中身が同じファイル（重複）は見つかりませんでした。")
        pause_and_exit()
        return

    # 見つかった重複を表示（各グループの先頭を「残す」候補にする）
    print(f"\n--- 重複が {len(groups)} グループ見つかりました ---")
    extras = []  # 移動候補（各グループの2つ目以降）
    for i, group in enumerate(groups, start=1):
        group = sorted(group, key=lambda p: str(p))
        size = group[0].stat().st_size
        print(f"\n[グループ{i}] 同じ中身・{human_size(size)}")
        for j, p in enumerate(group):
            mark = "残す" if j == 0 else "→ 移動候補"
            print(f"  {mark}: {p.relative_to(folder)}")
        extras.extend(group[1:])

    print(f"\n重複ぶん（残す1つを除いた）合計: {len(extras)} 件")
    answer = ask("これらを _duplicates フォルダへ移動しますか？ (yes/no)", "no")
    if answer.lower() not in ("yes", "y"):
        print("移動はしませんでした。一覧だけ表示しました。")
        pause_and_exit()
        return

    dup_dir = folder / "_duplicates"
    moved_records = []  # (元の場所, 移動先ファイル名, サイズ) … あとで元に戻せるよう記録する
    move_error = None
    try:
        dup_dir.mkdir(exist_ok=True)
        for p in extras:
            rel = str(p.relative_to(folder))
            size = p.stat().st_size
            target = unique_destination(dup_dir, p.name)
            p.rename(target)
            moved_records.append((rel, target.name, size))
    except OSError as e:
        move_error = e  # 途中で失敗しても、ここまでの記録は下で必ず残す

    # 「どこにあったファイルを動かしたか」をCSVに記録（平らに集めるので元の場所を残す）
    if moved_records:
        try:
            manifest = dup_dir / "duplicates_manifest.csv"
            is_new = not manifest.exists()
            with open(manifest, "a", newline="", encoding="utf-8-sig") as f:
                w = csv.writer(f)
                if is_new:
                    w.writerow(["元の場所", "移動先ファイル名", "サイズ(バイト)"])
                w.writerows(moved_records)
        except OSError:
            pass

    if move_error is not None:
        print(f"⚠ 移動中にエラーが起きました（{len(moved_records)}件まで移動済み）: {move_error}")
        pause_and_exit()
        return

    print(f"\n✅ 完了しました。{len(moved_records)} 件を {dup_dir} へ移動しました。")
    print(f"   元の場所は {dup_dir / 'duplicates_manifest.csv'} に記録しました。")
    pause_and_exit()


def pause_and_exit():
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass


if __name__ == "__main__":
    main()
