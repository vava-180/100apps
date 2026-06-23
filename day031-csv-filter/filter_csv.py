# -*- coding: utf-8 -*-
"""
CSV 列の抽出・絞り込みツール（Day 031）

1つのCSVから「必要な列だけ」を取り出し、さらに「条件に合う行だけ」に絞って
新しいCSVに書き出します。

例: 「氏名」「金額」列だけを残し、「金額が1000以上」の行だけを出力する。

しくみ:
  1) CSVを読み、見出し（先頭行）を番号付きで見せる
  2) 残す列を番号で選ぶ（例: 1,3,5 ／ 空Enterで全部）
  3) 任意で、1つの列に絞り込み条件を付ける（含む/等しい/含まない/数値の大小）
  4) プレビューし、yesなら『元名_抽出.csv』に書き出す
文字コードは UTF-8 と Shift_JIS(cp932) を自動で判別します。

外部ライブラリは使いません（標準ライブラリ csv のみ・ネット通信なし）。
元のCSVは書き換えません（読み取り＋新しいCSVの書き出しだけ）。
使い方: ターミナルで  python filter_csv.py   と実行するか、ファイルをダブルクリック。
"""

import csv
import io
import math
import sys
from pathlib import Path

try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass

# 絞り込み条件の選択肢 → 表示名（4〜7は数値として比較する）
OP_LABELS = {
    "1": "含む",
    "2": "等しい",
    "3": "含まない",
    "4": "数値が ＞",
    "5": "数値が ≧",
    "6": "数値が ＜",
    "7": "数値が ≦",
}
NUMERIC_OPS = ("4", "5", "6", "7")


# ===== 中心ロジック（ファイル不要・テストしやすい純粋関数）=====

def to_number(text: str):
    """文字列を数値にする。'1,200' や ' 3.5 ' も読む。数値でなければ None。

    カンマは「正しい桁区切り」のときだけ取り除く（例: 1,234 はOK、1,2 はNG）。
    """
    if text is None:
        return None
    s = text.strip()
    if s == "":
        return None
    if "," in s:
        sign = ""
        body = s
        if body[:1] in "+-":
            sign, body = body[0], body[1:]
        intpart, dot, frac = body.partition(".")
        groups = intpart.split(",")
        if len(groups) < 2:
            return None
        if not groups[0].isdigit() or not (1 <= len(groups[0]) <= 3):
            return None
        if any((not g.isdigit() or len(g) != 3) for g in groups[1:]):
            return None
        s = sign + intpart.replace(",", "") + dot + frac
    # 数字・小数点・符号 以外が混じる入力（'1e3' 'inf' 'nan' など）は数値扱いしない
    if any(ch not in "0123456789.+-" for ch in s):
        return None
    try:
        value = float(s)
    except ValueError:
        return None
    return value if math.isfinite(value) else None  # 桁あふれの inf も除く


def cell_value(row: list, index: int) -> str:
    """行の index 番目の値。列が足りない行でもエラーにせず空文字を返す。"""
    if 0 <= index < len(row):
        return row[index]
    return ""


def parse_index_list(raw: str, ncols: int):
    """「1,3,5」を [0,2,4] に変換する。空なら全列。範囲外や数字以外があれば None。"""
    raw = raw.strip()
    if raw == "":
        return list(range(ncols))
    result = []
    for part in raw.replace("，", ",").split(","):
        p = part.strip()
        if not p.isdigit():
            return None
        n = int(p)
        if not (1 <= n <= ncols):
            return None
        idx = n - 1
        if idx not in result:  # 同じ列の重複指定は1回にまとめる
            result.append(idx)
    return result if result else None


def row_passes(row: list, idx: int, op: str, target: str, case_sensitive: bool) -> bool:
    """1行が絞り込み条件に合うか。数値条件(4〜7)は両方が数値のときだけ比較する。

    条件をかける列そのものが無い（列数が足りない）行は、評価できないので
    どの条件でも対象外（False）にする。「空欄」と「列が無い」を区別するため。
    """
    if idx >= len(row):
        return False
    cell = row[idx]
    if op in NUMERIC_OPS:
        a = to_number(cell)
        b = to_number(target)
        if a is None or b is None:
            return False  # 数値でない行は数値条件に通さない
        if op == "4":
            return a > b
        if op == "5":
            return a >= b
        if op == "6":
            return a < b
        if op == "7":
            return a <= b
        return False
    # 文字の条件（含む/等しい/含まない）
    c, t = (cell, target) if case_sensitive else (cell.casefold(), target.casefold())
    if op == "1":
        return t in c
    if op == "2":
        return c == t
    if op == "3":
        return t not in c
    return False


def select_columns(row: list, indices: list) -> list:
    """指定した列だけを取り出す。列が足りない行は空文字で補う。"""
    return [cell_value(row, i) for i in indices]


# ===== ファイルの読み書き（Day030と同じ方針）=====

def read_csv_rows(path: Path):
    """CSVを読む。(見出し, データ行, 使った文字コード, エラー文) を返す。成功時エラー文=None。"""
    try:
        raw = path.read_bytes()
    except OSError as e:
        return None, None, None, f"ファイルを読めません: {e}"
    text = None
    used_enc = None
    for enc, label in (("utf-8-sig", "UTF-8"), ("cp932", "Shift_JIS(cp932)")):
        try:
            text = raw.decode(enc)
            used_enc = label
            break
        except UnicodeDecodeError:
            continue
    if text is None:
        return None, None, None, "文字コードを判別できません（UTF-8 / Shift_JIS のどちらでもありません）。"
    try:
        # StringIO(newline="") に渡すと、セル内の改行（"..\n.." のような正当な値）も保てる。
        # strict=True で、引用符の数が合わないなど壊れたCSVをエラーにできる。
        all_rows = list(csv.reader(io.StringIO(text, newline=""), strict=True))
    except csv.Error as e:
        return None, None, used_enc, f"CSVの形式が壊れている可能性があります（引用符の対応など）: {e}"
    if not all_rows:
        return None, None, used_enc, "中身が空です。"
    header = all_rows[0]
    data = all_rows[1:]
    if not header or all((h or "").strip() == "" for h in header):
        return None, None, used_enc, "先頭行（見出し）がありません。"
    return header, data, used_enc, None


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


def write_csv(path: Path, table: list):
    """CSVを書き出す。Excelで開きやすいよう UTF-8（BOM付き）。"x"で既存を上書きしない。"""
    with open(path, "x", encoding="utf-8-sig", newline="") as f:
        writer = csv.writer(f)
        writer.writerows(table)


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


def choose_column(header: list, prompt: str):
    """列を番号で選んでもらい、0始まりの列番号を返す。"""
    while True:
        raw = ask(prompt + "（番号）", "")
        if raw.isdigit():
            n = int(raw)
            if 1 <= n <= len(header):
                return n - 1
        print(f"⚠ 1〜{len(header)} の番号で入れてください。")


def main():
    print("=" * 48)
    print(" CSV 列の抽出・絞り込みツール（Day 031）")
    print("=" * 48)

    raw = ask("対象のCSVファイルのパス", "")
    if raw == "":
        print("⚠ パスが空です。")
        pause_and_exit()
        return
    path = Path(raw.strip('"'))
    if not path.is_file():
        print(f"⚠ ファイルが見つかりません: {path}")
        pause_and_exit()
        return

    header, rows, used_enc, error = read_csv_rows(path)
    if error is not None:
        print(f"⚠ CSVを読めませんでした: {error}")
        pause_and_exit()
        return
    print(f"（{used_enc} として読み込みました）")
    if not rows:
        print("⚠ 見出しだけで、対象のデータ行がありません。")
        pause_and_exit()
        return

    print("\n--- 列の一覧 ---")
    for i, name in enumerate(header, start=1):
        print(f"  {i}) {name}")

    # 残す列を選ぶ
    while True:
        indices = parse_index_list(ask("残す列（例 1,3,5 ／ 空Enterで全部）", ""), len(header))
        if indices is not None:
            break
        print(f"⚠ 1〜{len(header)} の番号をカンマ区切りで入れてください。")

    # 絞り込み条件（任意）
    use_filter = ask("行の絞り込み条件を付けますか？ (yes/no)", "no").lower() in ("yes", "y")
    op = target = None
    filt_idx = None
    case_sensitive = False
    if use_filter:
        filt_idx = choose_column(header, "条件をかける列")
        print("\n条件を選んでください:")
        for key, label in OP_LABELS.items():
            print(f"  {key}) {label}")
        op = ask("番号", "1").strip()
        if op not in OP_LABELS:
            print("⚠ 番号が正しくありません。")
            pause_and_exit()
            return
        target = ask("比べる値", "")
        if target == "":
            # 空の比べる値は分かりにくい挙動（全行一致など）になりやすいので確認する
            if op == "2":  # 「等しい」だけは“空欄の行を抜き出す”意図があり得る
                if ask("空欄の行を抽出しますか？ (yes/no)", "no").lower() not in ("yes", "y"):
                    print("条件を空にしたため中止しました。")
                    pause_and_exit()
                    return
            else:
                print("⚠ 比べる値が空です。条件を付ける場合は値を入れてください。")
                pause_and_exit()
                return
        if op not in NUMERIC_OPS:
            case_sensitive = ask("大文字小文字を区別しますか？ (yes/no)", "no").lower() in ("yes", "y")

    # --- 抽出してプレビュー ---
    out_rows = [select_columns(header, indices)]  # 1行目は見出し
    kept = 0
    for row in rows:
        if use_filter and not row_passes(row, filt_idx, op, target, case_sensitive):
            continue
        out_rows.append(select_columns(row, indices))
        kept += 1

    cond = f"／条件: {header[filt_idx]} が「{OP_LABELS[op]} {target}」" if use_filter else ""
    print(f"\n--- プレビュー（{kept} 行を抽出{cond}）---")
    for line in out_rows[:11]:  # 見出し＋先頭10行
        print("  " + " | ".join(line))
    if len(out_rows) > 11:
        print(f"  … ほか {len(out_rows) - 11} 行")

    if kept == 0:
        print("\n条件に合う行がありませんでした。")
        pause_and_exit()
        return

    if ask("\nこの内容でCSVに書き出しますか？ (yes/no)", "no").lower() not in ("yes", "y"):
        print("書き出しませんでした。プレビューのみです。")
        pause_and_exit()
        return

    base = path.with_name(f"{path.stem}_抽出.csv")
    out = None
    for _ in range(5):
        cand = unique_path(base)
        try:
            write_csv(cand, out_rows)
            out = cand
            break
        except FileExistsError:
            continue
        except OSError as e:
            print(f"⚠ 書き出しに失敗しました: {e}")
            pause_and_exit()
            return
    if out is None:
        print("⚠ 書き出し先の名前が用意できませんでした。")
        pause_and_exit()
        return

    print(f"\n✅ 完了しました。{kept} 行を書き出しました:\n   {out}")
    pause_and_exit()


if __name__ == "__main__":
    main()
