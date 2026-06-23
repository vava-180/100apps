# -*- coding: utf-8 -*-
"""
文字コード一括変換ツール（Day 029）

フォルダの中の複数テキストファイルの「文字コード」を、まとめて変換します。
日本語環境では UTF-8 と Shift_JIS(cp932) が混在しがちで、文字化けの原因になります。
このツールで、選んだ文字コードにそろえられます。

しくみ:
  1) 各ファイルの今の文字コードを自動で見分ける（BOM付きUTF-8 / UTF-8 / Shift_JIS）
  2) 選んだ文字コードに変換するとどうなるかをプレビュー（すでに同じ形のものはスキップ）
  3) yesなら変換して保存（任意で変換前の控え .bak を残す）
Shift_JISで表せない文字（絵文字など）を含むファイルは、データを壊さないよう丸ごとスキップします。

外部ライブラリは使いません（標準ライブラリ shutil のみ・ネット通信なし）。
使い方: ターミナルで  python convert_encoding.py   と実行するか、ファイルをダブルクリック。
"""

import re
import shutil
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# 変換先の選択肢 → (デコード用の表示名, encodeに使う文字コード, BOMを付けるか)
TARGETS = {
    "1": ("UTF-8（BOM無し）", "utf-8", False),
    "2": ("UTF-8（BOM付き・Excel向き）", "utf-8", True),
    "3": ("Shift_JIS（cp932）", "cp932", False),
}
BOM = b"\xef\xbb\xbf"


# ===== 変換の中心ロジック（ファイル不要・テストしやすい純粋関数）=====

def detect_decode(raw: bytes):
    """バイト列の文字コードを見分けて (本文, 元の文字コード名) を返す。読めなければ (None, None)。

    順番: BOM付きUTF-8 → BOM無しUTF-8 → Shift_JIS。
    Shift_JISはほぼどんなバイトも読めてしまうため、ヌル文字を含むものは
    画像などのバイナリとみなして対象外にする（中身を壊さないため）。
    """
    if b"\x00" in raw:
        return None, None
    if raw.startswith(BOM):
        # BOMは強い目印。BOM付きなのにUTF-8として読めない＝壊れている可能性が高いので、
        # cp932などにフォールバックせず対象外にする（誤判定で中身を壊さないため）
        try:
            return raw[len(BOM):].decode("utf-8"), "utf-8-sig"
        except UnicodeDecodeError:
            return None, None
    for enc in ("utf-8", "cp932"):
        try:
            return raw.decode(enc), enc
        except UnicodeDecodeError:
            continue
    return None, None


def encode_to(text: str, target_enc: str, add_bom: bool):
    """本文を変換先の文字コードのバイト列にする。表せない文字があれば None（＝スキップ対象）。"""
    try:
        data = text.encode(target_enc)  # errors既定=strict：表せない字は例外にして気づけるように
    except UnicodeEncodeError:
        return None
    if add_bom and target_enc == "utf-8":
        data = BOM + data
    return data


# ===== ファイルまわり =====

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
        if p.resolve() == self_resolved:
            continue
        if is_backup_name(p.name):
            continue
        if exts and p.suffix.lower() not in exts:
            continue
        files.append(p)
    return files


def normalize_exts(raw: str) -> list:
    """「.txt, csv ,.md」のような入力を ['.txt', '.csv', '.md'] に整える。"""
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


def write_bytes_atomic(path: Path, data: bytes):
    """同じフォルダに一時ファイルを書いてから置き換える。書き込み途中で失敗しても元ファイルを壊さない。"""
    tmp = path.with_name(path.name + ".tmp_convert")
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
    print(" 文字コード一括変換ツール（Day 029）")
    print("=" * 48)

    here = Path(__file__).parent
    raw = ask("変換したいフォルダのパス", str(here))
    folder = Path(raw.strip('"'))
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    print("\n変換先を選んでください:")
    for key, (label, _enc, _bom) in TARGETS.items():
        print(f"  {key}) {label}")
    choice = ask("番号", "1").strip()
    if choice not in TARGETS:
        print("⚠ 番号が正しくありません。")
        pause_and_exit()
        return
    label, target_enc, add_bom = TARGETS[choice]

    exts = normalize_exts(ask("対象の拡張子（カンマ区切り。未入力なら .txt,.csv,.md）", ".txt,.csv,.md"))
    recursive = ask("サブフォルダの中も対象にしますか？ (yes/no)", "no").lower() in ("yes", "y")

    files = collect_files(folder, recursive, exts, Path(__file__))
    if not files:
        print("対象ファイルが見つかりませんでした。")
        pause_and_exit()
        return

    # --- プレビュー（まだ書き換えない）---
    print(f"\n{len(files)} 件を確認しています…")
    plan = []        # (path, 元コード, 元バイト, 変換後バイト) … 変換が必要なものだけ
    unreadable = []  # 文字コードを見分けられない
    cant_encode = []  # 変換先で表せない文字を含む
    same = 0         # すでに同じ形

    for p in sorted(files, key=lambda x: str(x)):
        try:
            data = p.read_bytes()
        except OSError:
            unreadable.append(p)
            continue
        text, src_enc = detect_decode(data)
        if text is None:
            unreadable.append(p)
            continue
        new_bytes = encode_to(text, target_enc, add_bom)
        if new_bytes is None:
            cant_encode.append(p)
            continue
        if new_bytes == data:
            same += 1  # 変換しても中身が変わらない＝すでにその形
            continue
        plan.append((p, src_enc, data, new_bytes))

    if unreadable:
        print("⚠ 文字コードを見分けられず飛ばすファイル:")
        for p in unreadable:
            print(f"   {p.relative_to(folder)}")
    if cant_encode:
        print(f"⚠ {label} で表せない文字を含むため飛ばすファイル:")
        for p in cant_encode:
            print(f"   {p.relative_to(folder)}")
    if same:
        print(f"（すでに {label} と同じ形のため、そのままにするファイル: {same} 件）")

    if not plan:
        print("\n変換が必要なファイルはありませんでした。")
        pause_and_exit()
        return

    print(f"\n--- 変換プレビュー（{len(plan)} ファイルを {label} に）---")
    for p, src_enc, _data, _new in plan:
        print(f"   {src_enc:>9}  →  {label} : {p.relative_to(folder)}")

    make_backup = ask("変換前に控え(.bak)を残しますか？ (yes/no)", "yes").lower() in ("yes", "y")
    if ask("実行しますか？ (yes/no)", "no").lower() not in ("yes", "y"):
        print("実行しませんでした。プレビューのみです。")
        pause_and_exit()
        return

    # --- 実行：1ファイルずつ控え→書き込み。失敗してもそれまでの結果は残す ---
    done = 0
    changed = []  # プレビュー後に中身が変わったファイル（外部編集など）
    for p, _src_enc, orig_data, new_bytes in plan:
        try:
            # プレビュー時と中身が同じか確認（変わっていたら、古い結果で上書きしないよう飛ばす）
            if p.read_bytes() != orig_data:
                changed.append(p)
                continue
            if make_backup:
                shutil.copy2(p, backup_path(p))
            write_bytes_atomic(p, new_bytes)
            done += 1
        except OSError as e:
            print(f"⚠ 失敗（飛ばしました）: {p.relative_to(folder)} … {e}")

    print(f"\n✅ 完了しました。{done} / {len(plan)} ファイルを {label} に変換しました。")
    if changed:
        print("⚠ プレビュー後に内容が変わったため飛ばしたファイル:")
        for p in changed:
            print(f"   {p.relative_to(folder)}")
    if make_backup:
        print("   変換前の控えは、各ファイルと同じ場所に .bak で残しています。")
    pause_and_exit()


if __name__ == "__main__":
    main()
