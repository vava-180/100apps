# -*- coding: utf-8 -*-
"""
CSV集計・ピボットツール（Day 030）

1つのCSVを読み込み、選んだ列でまとめて集計します。
例: 「担当者」ごとに「金額」を合計する／「担当者 × 月」のクロス集計（ピボット表）を作る。

しくみ:
  1) CSVを読み、見出し（先頭行）と各列を番号付きで見せる
  2) 「行の見出しにする列」「（任意で）列の見出しにする列」「集計方法」「値の列」を選ぶ
  3) 集計結果をプレビューし、yesなら『元名_集計.csv』に書き出す
集計方法は 合計 / 件数 / 平均 / 最大 / 最小 から選べます。
文字コードは UTF-8 と Shift_JIS(cp932) を自動で判別します。

外部ライブラリは使いません（標準ライブラリ csv のみ・ネット通信なし）。
元のCSVは書き換えません（読み取り＋新しいCSVの書き出しだけ）。
使い方: ターミナルで  python aggregate.py   と実行するか、ファイルをダブルクリック。
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

# 集計方法の選択肢 → 表示名
AGG_LABELS = {
    "1": "合計",
    "2": "件数",
    "3": "平均",
    "4": "最大",
    "5": "最小",
}


# ===== 集計の中心ロジック（ファイル不要・テストしやすい純粋関数）=====

def to_number(text: str):
    """文字列を数値にする。'1,200' や ' 3.5 ' も読む。数値でなければ None。

    カンマは「正しい桁区切り」のときだけ取り除く（例: 1,234 はOK、1,2 や 12,34 はNG）。
    こうしないと '1,2' を 12 と誤読してしまい、集計値が静かに壊れる。
    """
    if text is None:
        return None
    s = text.strip()
    if s == "":
        return None
    if "," in s:
        sign = ""
        body = s
        if body[:1] in "+-":  # 先頭の符号はいったん外す
            sign, body = body[0], body[1:]
        intpart, dot, frac = body.partition(".")
        groups = intpart.split(",")
        # 1つ目は1〜3桁、それ以降はちょうど3桁、すべて数字、でなければ桁区切りとして不正
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
    """行の index 番目の値を返す。列が足りない行でもエラーにせず空文字を返す。"""
    if 0 <= index < len(row):
        return row[index]
    return ""


def aggregate(rows: list, row_idx: int, col_idx, value_idx, agg: str):
    """集計して (行キー一覧, 列キー一覧, 結果dict, 値スキップ数, キー欠け行数) を返す。

    row_idx … 行の見出しにする列の番号
    col_idx … 列の見出しにする列の番号（ピボットしないなら None）
    value_idx … 集計する値の列の番号（件数のときは使わないので None でよい）
    agg … "1"合計 "2"件数 "3"平均 "4"最大 "5"最小
    返り値の結果dictは {(行キー,列キー): 数値}。
    value_skipped … 値を数値にできず飛ばした件数。
    key_short … 行/列の見出し列そのものが無い（列数が足りない）ため除外した行数。
    """
    # 見出しに使う列。これが無い（列数不足）行は、別グループに混ぜず除外する
    key_indexes = [row_idx] + ([col_idx] if col_idx is not None else [])

    buckets = {}      # キー -> 数値のリスト
    counts = {}       # キー -> 行の個数（件数用）
    row_keys = []     # 出てきた順を保ちつつ重複なし
    col_keys = []
    value_skipped = 0  # 値を数値にできず飛ばした件数
    key_short = 0      # 見出し列が欠けていて除外した行数

    for row in rows:
        # 見出し列が1つでも無い（短すぎる）行は、誤って ""グループに入れず除外する
        if any(idx >= len(row) for idx in key_indexes):
            key_short += 1
            continue
        rkey = row[row_idx]
        ckey = row[col_idx] if col_idx is not None else ""
        if rkey not in row_keys:
            row_keys.append(rkey)
        if ckey not in col_keys:
            col_keys.append(ckey)
        key = (rkey, ckey)
        counts[key] = counts.get(key, 0) + 1
        if agg != "2":  # 件数以外は値の数値が必要
            num = to_number(cell_value(row, value_idx))
            if num is None:
                value_skipped += 1
                continue
            buckets.setdefault(key, []).append(num)

    result = {}
    for rkey in row_keys:
        for ckey in col_keys:
            key = (rkey, ckey)
            if agg == "2":  # 件数
                if key in counts:
                    result[key] = counts[key]
                continue
            nums = buckets.get(key)
            if not nums:
                continue  # そのマスに数値が1つもなければ空欄にする
            if agg == "1":
                result[key] = sum(nums)
            elif agg == "3":
                result[key] = sum(nums) / len(nums)
            elif agg == "4":
                result[key] = max(nums)
            elif agg == "5":
                result[key] = min(nums)

    # 見やすさのため、最後に行キー・列キーを文字列順に並べ替える（出現順ではない）
    row_keys.sort()
    col_keys.sort()
    return row_keys, col_keys, result, value_skipped, key_short


def format_number(value, is_average: bool = False) -> str:
    """集計結果を見やすい文字列にする。整数なら小数点を付けない。

    平均は小数2桁にそろえる。合計・最大・最小は精度を落とさず、
    ただし 0.30000000000000004 のような誤差表示は避けて末尾の0を整える。
    """
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if value.is_integer():
            return str(int(value))
        if is_average:
            return f"{value:.2f}"
        # 合計などは値を残しつつ、浮動小数の誤差で末尾が汚れないよう整える
        return f"{value:.6f}".rstrip("0").rstrip(".")
    return str(value)


def build_table(row_keys, col_keys, result, row_header, value_header, pivot, agg):
    """書き出し用の二次元リスト（先頭行が見出し）を作る。agg は "1"〜"5"。"""
    is_avg = agg == "3"
    agg_label = AGG_LABELS[agg]
    table = []
    if pivot:
        # クロス集計：1行目は ["行見出し名", 列キー1, 列キー2, ...]
        table.append([row_header] + list(col_keys))
        for rkey in row_keys:
            line = [rkey]
            for ckey in col_keys:
                v = result.get((rkey, ckey))
                line.append("" if v is None else format_number(v, is_avg))
            table.append(line)
    else:
        # 単純集計：2列 ["行見出し名", "集計方法(値の列名)"]
        head = f"{agg_label}（{value_header}）" if value_header else agg_label
        table.append([row_header, head])
        for rkey in row_keys:
            v = result.get((rkey, ""))
            table.append([rkey, "" if v is None else format_number(v, is_avg)])
    return table


# ===== ファイルの読み書き =====

def read_csv_rows(path: Path):
    """CSVを読む。(見出し, データ行, 使った文字コード, エラー文) を返す。

    成功時はエラー文が None。失敗時は見出し=None とエラー文を返す。
    文字コードは UTF-8（BOM有無）→ Shift_JIS(cp932) の順に試す。
    """
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
    # 見出しが空、または空セルばかりなら、列を選べないのでエラー扱い
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
    """集計表をCSVに書き出す。Excelで開きやすいよう UTF-8（BOM付き）で保存。

    "x"（新規作成専用）で開くので、万一その瞬間に同名ファイルがあれば
    上書きせず FileExistsError になる（呼び出し側で別名にやり直す）。
    """
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


def choose_column(header: list, prompt: str, allow_empty: bool = False):
    """列を番号で選んでもらい、0始まりの列番号を返す。allow_empty=True なら空Enterで None。"""
    while True:
        raw = ask(prompt + "（番号）", "")
        if raw == "" and allow_empty:
            return None
        if raw.isdigit():
            n = int(raw)
            if 1 <= n <= len(header):
                return n - 1  # 画面は1始まり、内部は0始まり
        print(f"⚠ 1〜{len(header)} の番号で入れてください。")


def main():
    print("=" * 48)
    print(" CSV集計・ピボットツール（Day 030）")
    print("=" * 48)

    raw = ask("集計したいCSVファイルのパス", "")
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
        print("⚠ 見出しだけで、集計するデータ行がありません。")
        pause_and_exit()
        return

    print("\n--- 列の一覧 ---")
    for i, name in enumerate(header, start=1):
        print(f"  {i}) {name}")

    row_idx = choose_column(header, "行の見出しにする列")
    col_idx = choose_column(header, "列の見出しにする列（ピボットしないなら空Enter）", allow_empty=True)
    pivot = col_idx is not None

    print("\n集計方法を選んでください:")
    for key, label in AGG_LABELS.items():
        print(f"  {key}) {label}")
    agg = ask("番号", "1").strip()
    if agg not in AGG_LABELS:
        print("⚠ 番号が正しくありません。")
        pause_and_exit()
        return

    value_idx = None
    value_header = ""
    if agg != "2":  # 件数以外は「集計する値の列」が必要
        value_idx = choose_column(header, "集計する値の列")
        value_header = header[value_idx]

    # --- 集計してプレビュー ---
    row_keys, col_keys, result, value_skipped, key_short = aggregate(
        rows, row_idx, col_idx, value_idx, agg)
    table = build_table(row_keys, col_keys, result, header[row_idx], value_header, pivot, agg)

    if key_short:
        print(f"\n（見出しの列が欠けていて集計から外した行: {key_short} 件）")
    if value_skipped:
        print(f"（数値として読めず集計から外した値: {value_skipped} 件）")
    if not row_keys:
        print("\n集計できるデータがありませんでした。")
        pause_and_exit()
        return

    print(f"\n--- プレビュー（{AGG_LABELS[agg]}）---")
    preview_rows = table[:11]  # 見出し＋先頭10行まで
    for line in preview_rows:
        print("  " + " | ".join(str(c) for c in line))
    if len(table) > len(preview_rows):
        print(f"  … ほか {len(table) - len(preview_rows)} 行")

    if ask("\nこの内容でCSVに書き出しますか？ (yes/no)", "no").lower() not in ("yes", "y"):
        print("書き出しませんでした。プレビューのみです。")
        pause_and_exit()
        return

    base = path.with_name(f"{path.stem}_集計.csv")
    out = None
    for _ in range(5):  # 書き込み直前に同名ができても、別名にやり直す
        cand = unique_path(base)
        try:
            write_csv(cand, table)
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

    print(f"\n✅ 完了しました。結果を書き出しました:\n   {out}")
    pause_and_exit()


if __name__ == "__main__":
    main()
