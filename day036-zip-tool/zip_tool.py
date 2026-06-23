# -*- coding: utf-8 -*-
"""
ZIP一括 圧縮・解凍ツール（Day 036）

フォルダの中のファイルを1つのZIPにまとめたり、フォルダの中にある複数のZIPを
まとめて解凍したりします。

しくみ:
  1) モードを選ぶ（圧縮／解凍）
  2) 圧縮: フォルダ内のファイルを1つのZIPにまとめる（サブフォルダ構造も保てる）
     解凍: フォルダ内の各ZIPを、それぞれ専用フォルダに展開する
解凍では、ZIPの中に「.. で親フォルダの外へ書き出す」ような細工（Zip Slip）が
あっても、指定フォルダの外には絶対に書き出さないよう守ります。

外部ライブラリは使いません（標準ライブラリ zipfile / shutil / os / sys / pathlib のみ・ネット通信なし）。
既にあるZIP・フォルダは上書きしません（連番を付けて新規作成）。
使い方: ターミナルで  python zip_tool.py   と実行するか、ファイルをダブルクリック。
"""

import os
import shutil
import sys
import zipfile
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass


# ===== 中心ロジック（テストしやすい純粋関数）=====

def is_within(base: Path, target: Path) -> bool:
    """target が base の中（または base 自身）かどうか。"""
    try:
        target.relative_to(base)
        return True
    except ValueError:
        return False


def collect_files(folder: Path, recursive: bool, exclude: set):
    """ZIPに入れるファイルを集める。(ファイル一覧, 除いたリンク数) を返す。

    exclude（絶対パスの集合）と、シンボリックリンクは除く。
    リンクを入れると、フォルダ内のリンク名で「外の実体」をZIPに取り込んでしまうため。
    """
    files = []
    skipped_links = 0
    if recursive:
        for root, _dirs, names in os.walk(folder):  # followlinks=False（フォルダリンクは辿らない）
            for name in names:
                p = Path(root) / name
                if p.is_symlink():
                    skipped_links += 1
                    continue
                if p.resolve() not in exclude:
                    files.append(p)
    else:
        for p in folder.iterdir():
            if not p.is_file():
                continue
            if p.is_symlink():
                skipped_links += 1
                continue
            if p.resolve() not in exclude:
                files.append(p)
    return files, skipped_links


def safe_members(zf: zipfile.ZipFile, dest_dir: Path):
    """ZIPの各項目を (情報, 展開先Path) にして返す。外へ出る項目は除外して別に報告する。

    戻り値: (安全な項目のリスト, 危険でスキップした名前のリスト)
    """
    dest_resolved = dest_dir.resolve()
    safe = []
    skipped = []
    seen = set()  # 同じ展開先になる項目（重複・大文字小文字違い）を1回だけにする
    for info in zf.infolist():
        target = (dest_resolved / info.filename).resolve()
        # 展開先が dest_dir の外（.. や絶対パスの細工）なら拒否
        if target != dest_resolved and not is_within(dest_resolved, target):
            skipped.append(info.filename)
            continue
        if not info.is_dir():
            # Windowsは大文字小文字を区別しないので casefold でそろえて重複判定
            key = str(target).casefold()
            if key in seen:
                skipped.append(info.filename)  # ZIP内部での上書きを防ぐ
                continue
            seen.add(key)
        safe.append((info, target))
    return safe, skipped


# ===== ファイル書き出しの補助 =====

def unique_path(path: Path):
    """同名のファイル/フォルダがあれば連番を付ける。空き名が無ければ None。"""
    if not path.exists():
        return path
    for i in range(2, 1000):
        cand = path.with_name(f"{path.stem}({i}){path.suffix}")
        if not cand.exists():
            return cand
    return None


def cleanup_dir(path: Path):
    """解凍に失敗したとき、作りかけの展開先フォルダを片付ける（中途半端を残さない）。"""
    shutil.rmtree(path, ignore_errors=True)
    if path.exists():
        print(f"   （途中まで展開したファイルが残りました: {path.name}/）")


def extract_zip(zip_path: Path, dest_dir: Path):
    """1つのZIPを dest_dir に安全に展開する。(展開数, スキップした危険な名前) を返す。"""
    extracted = 0
    with zipfile.ZipFile(zip_path) as zf:
        safe, skipped = safe_members(zf, dest_dir)
        for info, target in safe:
            if info.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            # 中身を1ファイルずつ書き出す（大きいZIPでも一気にメモリへ載せない）
            with zf.open(info) as src, open(target, "wb") as out:
                shutil.copyfileobj(src, out)
            extracted += 1
    return extracted, skipped


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


def do_compress():
    here = str(Path(__file__).parent)
    folder = Path(ask("圧縮したいファイルが入ったフォルダ", here).strip('"'))
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        return
    recursive = ask("サブフォルダの中も含めますか？ (yes/no)", "yes").lower() in ("yes", "y")

    # ZIPの名前はファイル名だけ受け付ける（..\ や subdir\ で別の場所に作らせない）
    out_name = Path(ask("作るZIPの名前", f"{folder.name}.zip").strip('"')).name
    if not out_name:
        print("⚠ ZIPの名前が空です。")
        return
    if not out_name.lower().endswith(".zip"):
        out_name += ".zip"
    out_zip = unique_path(folder.parent / out_name)
    if out_zip is None:
        print("⚠ 出力ZIPの名前を用意できませんでした。")
        return

    # 自分自身（このスクリプト）と、これから作るZIPは入れない
    exclude = {Path(__file__).resolve(), out_zip.resolve()}
    files, skipped_links = collect_files(folder, recursive, exclude)
    if skipped_links:
        print(f"（安全のため、ショートカット/リンク {skipped_links} 個は対象外にしました）")
    if not files:
        print("圧縮するファイルが見つかりませんでした。")
        return

    print(f"\n{len(files)} 個のファイルを『{out_zip.name}』にまとめます。")
    if ask("実行しますか？ (yes/no)", "yes").lower() not in ("yes", "y"):
        print("実行しませんでした。")
        return

    added = 0
    failed = 0
    try:
        # "x"=新規作成専用。既存ZIPを上書きしない
        with zipfile.ZipFile(out_zip, "x", zipfile.ZIP_DEFLATED) as zf:
            for p in files:
                try:
                    arcname = p.relative_to(folder)  # フォルダ内の構造を保つ
                    zf.write(p, arcname)
                    added += 1
                except OSError as e:
                    failed += 1
                    print(f"⚠ 入れられず飛ばしました: {p.name} … {e}")
    except OSError as e:
        print(f"⚠ ZIP作成に失敗しました: {e}")
        return
    if failed:
        print(f"\n△ 一部失敗: {added} 個をまとめ、{failed} 個は入れられませんでした:\n   {out_zip}")
    else:
        print(f"\n✅ {added} 個をまとめました:\n   {out_zip}")


def do_extract():
    here = str(Path(__file__).parent)
    folder = Path(ask("ZIPが入っているフォルダ", here).strip('"'))
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        return
    zips = sorted(p for p in folder.iterdir() if p.is_file() and p.suffix.lower() == ".zip")
    if not zips:
        print("ZIPファイルが見つかりませんでした。")
        return

    print(f"\n{len(zips)} 個のZIPを、それぞれ専用フォルダに解凍します。")
    if ask("実行しますか？ (yes/no)", "yes").lower() not in ("yes", "y"):
        print("実行しませんでした。")
        return

    for zp in zips:
        dest = unique_path(folder / zp.stem)  # ZIP名のフォルダに展開（上書きしない）
        if dest is None:
            print(f"⚠ {zp.name}: 展開先フォルダ名を用意できませんでした。")
            continue
        try:
            dest.mkdir()
            count, skipped = extract_zip(zp, dest)
            msg = f"✅ {zp.name} → {dest.name}/（{count} 個）"
            if skipped:
                msg += f" ※安全のため除外: {len(skipped)} 個（フォルダ外へ出る/重複する項目）"
            print(msg)
        except zipfile.BadZipFile:
            cleanup_dir(dest)
            print(f"⚠ {zp.name}: 壊れているか、ZIPではありません。飛ばしました。")
        except RuntimeError:
            # 暗号化ZIPなど（パスワード付き）は zf.open で RuntimeError になる
            cleanup_dir(dest)
            print(f"⚠ {zp.name}: パスワード付き等で読めません。飛ばしました。")
        except OSError as e:
            cleanup_dir(dest)
            print(f"⚠ {zp.name}: 解凍に失敗しました … {e}")


def main():
    print("=" * 48)
    print(" ZIP一括 圧縮・解凍ツール（Day 036）")
    print("=" * 48)
    print("\nやることを選んでください:")
    print("  1) 圧縮（フォルダの中身を1つのZIPに）")
    print("  2) 解凍（フォルダ内のZIPを展開）")
    mode = ask("番号", "1").strip()
    if mode == "1":
        do_compress()
    elif mode == "2":
        do_extract()
    else:
        print("⚠ 1 か 2 を選んでください。")
    pause_and_exit()


if __name__ == "__main__":
    main()
