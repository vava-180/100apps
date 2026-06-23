# -*- coding: utf-8 -*-
"""
複数CSV結合ツール（Day 022）

フォルダの中にある複数のCSVファイルを、1つのCSVにまとめる実務ツールです。
- 1つ目のCSVの見出し（ヘッダー）を基準にします
- 見出しがちがうファイルがあれば警告し、列をそろえて結合します
- 「どのファイル由来か」の列を付けることもできます

外部ライブラリは使いません（標準ライブラリ csv のみ・ネット通信なし）。
使い方: ターミナルで  python merge.py   と実行するか、ファイルをダブルクリック。
"""

import csv
import sys
from pathlib import Path

# Windowsのコンソールで表示できない文字が混じっても止まらないようにする
try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass


# ===== CSVを結合する中心の処理（画面表示と分けてテストできるようにする）=====

def combine(tables: list, add_source: bool) -> tuple:
    """複数のCSV（見出し＋データ）を1つにまとめる。

    tables : [(ファイル名, 行のリスト), ...]
             行のリストは [[見出し...], [データ...], ...] の二次元
    add_source : True なら先頭に「元ファイル」列を足す

    戻り値: (まとめた見出し, まとめたデータ行, 警告メッセージのリスト)
    """
    warnings = []
    base_header = None
    merged_rows = []

    for name, rows in tables:
        if not rows:
            warnings.append(f"{name}: 中身が空のためスキップしました")
            continue
        header = rows[0]
        body = rows[1:]

        # 見出しに同じ名前の列があると、どの列か区別できないのでスキップする
        if has_duplicate(header):
            warnings.append(f"{name}: 見出しに同じ名前の列があるためスキップしました")
            continue

        if base_header is None:
            base_header = header
            # 基準ファイルの行も、見出しの列数にそろえる（過不足を直す）
            body = [fit_row(r, len(base_header)) for r in body]
        elif header == base_header:
            body = [fit_row(r, len(base_header)) for r in body]
        else:
            # 見出しがちがう場合は、基準の見出しに合わせて並べ替える
            warnings.append(f"{name}: 見出しが1つ目のファイルとちがいます（列をそろえて結合します）")
            body = [align_row(header, base_header, r) for r in body]

        if add_source:
            body = [[name] + r for r in body]
        merged_rows.extend(body)

    if base_header is None:
        return ([], [], warnings)

    out_header = (["元ファイル"] + base_header) if add_source else base_header
    return (out_header, merged_rows, warnings)


def has_duplicate(header: list) -> bool:
    """見出しの中に、同じ名前の列が2つ以上ないか調べる。"""
    seen = set()
    for col in header:
        if col in seen:
            return True
        seen.add(col)
    return False


def fit_row(row: list, n: int) -> list:
    """行の列数を n にそろえる（足りなければ空文字で埋め、多ければ切り捨てる）。"""
    return (list(row) + [""] * n)[:n]


def align_row(src_header: list, base_header: list, row: list) -> list:
    """見出しがちがう行を、基準の見出しの順番に並べ替える。
    基準にない列は捨て、足りない列は空にする。
    """
    # 元の「見出し→値」の対応を作る
    pair = {}
    for i, col in enumerate(src_header):
        pair[col] = row[i] if i < len(row) else ""
    # 基準の見出しの順に値を取り出す（なければ空）
    return [pair.get(col, "") for col in base_header]


# ===== ファイルの読み書き =====

def read_csv(path: Path):
    """CSVを読み込んで二次元リストにする。文字コードはUTF-8→Shift_JISの順に試す。
    どちらでも読めなければ None を返す（文字化けしたまま結合しないため）。
    """
    for enc in ("utf-8-sig", "cp932"):
        try:
            with open(path, newline="", encoding=enc) as f:
                return list(csv.reader(f))
        except UnicodeDecodeError:
            continue
    return None


def write_csv(path: Path, header: list, rows: list):
    """結果のCSVを書き出す。Excelで開きやすいよう UTF-8(BOM付き) にする。"""
    with open(path, "w", newline="", encoding="utf-8-sig") as f:
        writer = csv.writer(f)
        if header:
            writer.writerow(header)
        writer.writerows(rows)


# ===== 画面とのやり取り =====

def ask(prompt: str, default: str = "") -> str:
    suffix = f"（未入力なら {default}）" if default else ""
    value = input(f"{prompt}{suffix}: ").strip()
    return value if value else default


def main():
    print("=" * 48)
    print(" 複数CSV結合ツール（Day 022）")
    print("=" * 48)

    here = Path(__file__).parent
    raw = ask("CSVが入っているフォルダのパス", str(here))
    folder = Path(raw)
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        pause_and_exit()
        return

    # フォルダ直下の .csv を集める（結果ファイルは大文字小文字を問わず除く）
    out_name = "merged.csv"
    csv_files = sorted([p for p in folder.iterdir()
                        if p.is_file() and p.suffix.lower() == ".csv" and p.name.lower() != out_name.lower()])

    if len(csv_files) < 1:
        print("CSVファイルが見つかりませんでした。")
        pause_and_exit()
        return

    print(f"\n見つかったCSV: {len(csv_files)} 件")
    for p in csv_files:
        print(f"  - {p.name}")

    add_source = ask("\n「元ファイル」の列を付けますか？ (yes/no)", "yes").lower() in ("yes", "y")

    # 読み込む（文字コード不明・読み取り不可のファイルは結合せずスキップ）
    tables = []
    for p in csv_files:
        try:
            rows = read_csv(p)
        except OSError as e:
            print(f"  ⚠ 読み取り失敗のためスキップ: {p.name}（{e}）")
            continue
        if rows is None:
            print(f"  ⚠ 文字コードが判別できないためスキップ: {p.name}")
            continue
        tables.append((p.name, rows))

    if not tables:
        print("\n読み込めるCSVがありませんでした。")
        pause_and_exit()
        return

    header, rows, warnings = combine(tables, add_source)

    if warnings:
        print("\n--- 注意 ---")
        for w in warnings:
            print(f"  ⚠ {w}")

    if not rows:
        print("\n結合できるデータがありませんでした。")
        pause_and_exit()
        return

    print(f"\n結合後: {len(rows)} 行（見出し {len(header)} 列）")
    answer = ask(f"{out_name} として書き出しますか？ (yes/no)", "yes")
    if answer.lower() not in ("yes", "y"):
        print("中止しました。ファイルは作成していません。")
        pause_and_exit()
        return

    out_path = folder / out_name
    try:
        write_csv(out_path, header, rows)
    except OSError as e:
        print(f"⚠ 書き出しに失敗しました: {e}")
        pause_and_exit()
        return

    print(f"\n✅ 完了しました: {out_path}")
    pause_and_exit()


def pause_and_exit():
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass


if __name__ == "__main__":
    main()
