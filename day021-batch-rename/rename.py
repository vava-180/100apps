# -*- coding: utf-8 -*-
"""
ファイル一括リネームツール（Day 021）

フォルダの中のファイル名を、まとめて変更する実務ツールです。
- 変更前に「変更前 → 変更後」を必ずプレビューします
- 「はい」と答えたときだけ、実際に名前を変更します（誤操作を防ぐため）
- 同じ名前ができてしまう（上書きの危険がある）場合は、実行せず中止します

外部ライブラリは使いません（標準ライブラリのみ・ネット通信なし）。
使い方: ターミナルで  python rename.py   と実行するか、ファイルをダブルクリック。
"""

import re
import sys
import uuid
from pathlib import Path

# Windowsのコンソールで、表示できない文字が混じってもエラーで止まらないようにする
# （文字コード自体は変えず、表示できない字だけ別記号に置きかえる）
try:
    sys.stdout.reconfigure(errors="replace")
except Exception:
    pass


# ===== 名前を計算する部分（画面表示とは分けて、ここだけでテストできるようにする）=====

def make_new_name(name: str, mode: str, params: dict, index: int) -> str:
    """1つのファイル名から、新しいファイル名を計算して返す。

    name   : 元のファイル名（例 "report.txt"）
    mode   : "seq"(連番) / "replace"(置換) / "affix"(接頭辞・接尾辞)
    params : モードごとの設定（下の main で作る）
    index  : 連番モードで使う通し番号（0から始まる）
    """
    # 拡張子は「最後の1つ」だけを保持する（例: archive.tar.gz は .gz を拡張子とみなす）
    stem = Path(name).stem        # 拡張子を除いた部分（"report"）
    ext = Path(name).suffix       # 拡張子（".txt"）

    if mode == "seq":
        # 連番モード： base + 0埋めした番号 + 拡張子
        base = params["base"]
        start = params["start"]
        digits = params["digits"]
        number = str(start + index).zfill(digits)  # 例 digits=3 → "001"
        return f"{base}{number}{ext}"

    if mode == "replace":
        # 置換モード：名前（拡張子を除く）の中の文字を置き換える
        new_stem = stem.replace(params["find"], params["to"])
        return f"{new_stem}{ext}"

    if mode == "affix":
        # 接頭辞・接尾辞モード：前と後ろに文字を足す
        return f"{params['prefix']}{stem}{params['suffix']}{ext}"

    # ここには来ない想定だが、安全のため元の名前を返す
    return name


def build_rename_plan(files: list, mode: str, params: dict) -> list:
    """ファイル一覧から「(元の名前, 新しい名前)」のリストを作る。
    名前が変わらないものは除く。
    """
    plan = []
    for i, name in enumerate(files):
        new_name = make_new_name(name, mode, params, i)
        if new_name != name:
            plan.append((name, new_name))
    return plan


def find_collisions(files: list, plan: list) -> list:
    """変更後に名前がぶつかる（上書きの危険がある）ものを探して返す。

    - 新しい名前どうしが重複していないか
    - 変更しないファイルと同じ名前にならないか
    """
    problems = []

    # 変更後の全ファイル名の一覧を作る（変更しないものはそのまま）
    changed_from = {old for old, _ in plan}
    result_names = [name for name in files if name not in changed_from]
    result_names += [new for _, new in plan]

    # 重複している名前を集める
    seen = set()
    dup = set()
    for n in result_names:
        key = n.lower()  # Windowsは大文字小文字を区別しないので小文字でそろえて比較
        if key in seen:
            dup.add(key)
        seen.add(key)

    for old, new in plan:
        if new.lower() in dup:
            problems.append((old, new))
    return problems


# Windowsで「ファイル名として使えない」予約語（拡張子を除いた部分で判定）
WINDOWS_RESERVED = {"CON", "PRN", "AUX", "NUL"} \
    | {f"COM{i}" for i in range(1, 10)} | {f"LPT{i}" for i in range(1, 10)}


def invalid_reason(name: str):
    """新しいファイル名がWindowsで使えない場合、その理由（文字列）を返す。
    問題なければ None を返す。
    """
    if not name or name in (".", ".."):
        return "名前が空です"
    if re.search(r'[\\/:*?"<>|]', name):
        return '使えない文字（ \\ / : * ? " < > | ）が含まれています'
    if name != name.rstrip(" ."):
        return "名前の末尾にスペースかドットがあります"
    if Path(name).stem.upper() in WINDOWS_RESERVED:
        return "Windowsの予約語（CON や PRN など）は名前に使えません"
    return None


def apply_renames(folder: Path, plan: list):
    """リネームを実際に行う。

    A→B, B→C のような連鎖や A→B, B→A のような入れ替えでも安全にできるよう、
    いったん全部を一時的な名前に退避してから、最終的な名前に変える「2段階」方式。
    途中で失敗したら、できる限り元の名前に戻す（ロールバック）。

    戻り値: (状態, 失敗した名前, エラー内容, 変更できた件数)
            状態は "ok" / "error"
    """
    token = uuid.uuid4().hex
    staged = []  # (一時パス, 元の名前, 新しい名前)

    # --- 1段階目：元の名前 → 一時的な名前 ---
    for i, (old, new) in enumerate(plan):
        tmp = folder / f"__rename_tmp_{token}_{i}__"
        try:
            (folder / old).rename(tmp)
            staged.append((tmp, old, new))
        except OSError as e:
            # 退避中に失敗 → ここまで退避した分を元に戻す
            for tmp2, old2, _ in reversed(staged):
                try:
                    tmp2.rename(folder / old2)
                except OSError:
                    pass
            return ("error", old, str(e), 0)

    # --- 2段階目：一時的な名前 → 新しい名前 ---
    for idx, (tmp, old, new) in enumerate(staged):
        try:
            tmp.rename(folder / new)
        except OSError as e:
            # 失敗 → できる限り全部を元の名前に戻す
            for tmp2, old2, new2 in staged[:idx]:          # すでに新名に変えた分
                try:
                    (folder / new2).rename(folder / old2)
                except OSError:
                    pass
            for tmp2, old2, _ in staged[idx:]:             # まだ一時名の分
                try:
                    tmp2.rename(folder / old2)
                except OSError:
                    pass
            return ("error", new, str(e), 0)

    return ("ok", None, None, len(staged))


# ===== ここから下は、画面とのやり取り（入力・表示）=====

def ask(prompt: str, default: str = "") -> str:
    """入力を受け取る。空のままEnterなら default を使う。"""
    suffix = f"（未入力なら {default}）" if default else ""
    value = input(f"{prompt}{suffix}: ").strip()
    return value if value else default


def choose_folder() -> "Path | None":
    """対象フォルダを選ぶ。未入力ならこのスクリプトと同じ場所にする。
    見つからないときは None を返す。
    """
    here = Path(__file__).parent
    raw = ask("対象フォルダのパス", str(here))
    folder = Path(raw)
    if not folder.is_dir():
        print(f"⚠ フォルダが見つかりません: {folder}")
        return None
    return folder


def main():
    print("=" * 48)
    print(" ファイル一括リネームツール（Day 021）")
    print("=" * 48)

    folder = choose_folder()
    if folder is None:
        pause_and_exit()
        return

    # フォルダ直下のファイルだけを対象にする（サブフォルダやフォルダ自身は除く）。
    # 「.」で始まる隠しファイル（.env など）は、うっかり変えないよう既定で対象外にする。
    files = sorted([p.name for p in folder.iterdir() if p.is_file() and not p.name.startswith(".")])
    # このスクリプト自身は対象から外す（自分の名前を変えないように）
    self_name = Path(__file__).name
    files = [f for f in files if f != self_name]

    if not files:
        print("対象になるファイルがありません。")
        pause_and_exit()
        return

    print(f"\n対象フォルダ: {folder}")
    print(f"ファイル数: {len(files)} 件\n")

    print("どの方法で名前を変えますか？")
    print("  1) 連番をつける（例: 写真001.jpg, 写真002.jpg …）")
    print("  2) 文字を置きかえる（名前の中の文字を別の文字に）")
    print("  3) 前後に文字を足す（接頭辞・接尾辞）")
    choice = ask("番号を選ぶ", "1")

    if choice == "1":
        mode = "seq"
        base = ask("名前の先頭につける文字", "file_")
        start = int_or(ask("開始番号", "1"), 1)
        digits = int_or(ask("番号の桁数（3なら001）", "3"), 3)
        if start < 0:
            print("⚠ 開始番号は0以上にしてください。中止します。")
            pause_and_exit()
            return
        if digits < 1:
            print("⚠ 番号の桁数は1以上にしてください。中止します。")
            pause_and_exit()
            return
        params = {"base": base, "start": start, "digits": digits}
    elif choice == "2":
        mode = "replace"
        find = ask("置きかえる前の文字")
        if not find:
            print("⚠ 置きかえる文字が空です。中止します。")
            pause_and_exit()
            return
        params = {"find": find, "to": ask("置きかえた後の文字（空なら削除）", "")}
    elif choice == "3":
        mode = "affix"
        params = {"prefix": ask("前に足す文字", ""), "suffix": ask("後ろに足す文字", "")}
    else:
        print("⚠ 番号が正しくありません。中止します。")
        pause_and_exit()
        return

    # 変更の計画を作ってプレビュー表示
    plan = build_rename_plan(files, mode, params)
    if not plan:
        print("\n名前が変わるファイルはありませんでした。")
        pause_and_exit()
        return

    print("\n--- 変更プレビュー（まだ実行していません）---")
    for old, new in plan:
        print(f"  {old}  →  {new}")
    print(f"--- {len(plan)} 件を変更します ---")

    # 新しい名前がWindowsで使える形かチェック（使えない文字・予約語・末尾の空白など）
    bad_names = [(old, new, invalid_reason(new)) for old, new in plan if invalid_reason(new)]
    if bad_names:
        print("\n⚠ 使えない名前ができてしまうため、中止します:")
        for old, new, reason in bad_names:
            print(f"  {old}  →  {new}  （{reason}）")
        pause_and_exit()
        return

    # 名前の衝突チェック（上書きの危険を防ぐ）
    collisions = find_collisions(files, plan)
    if collisions:
        print("\n⚠ 変更すると名前がぶつかる（上書きの危険がある）ため、中止します:")
        for old, new in collisions:
            print(f"  {old}  →  {new}")
        pause_and_exit()
        return

    # 最終確認
    answer = ask("\n本当に実行しますか？ (yes/no)", "no")
    if answer.lower() not in ("yes", "y"):
        print("中止しました。ファイルは変更していません。")
        pause_and_exit()
        return

    # 実行（2段階リネーム。連鎖や入れ替えでも安全。失敗時はできる限り元に戻す）
    status, name, error, count = apply_renames(folder, plan)
    if status == "error":
        print(f"\n⚠ 「{name}」の変更でエラーが起きたため、中止して元に戻しました。")
        print(f"   理由: {error}")
        print("   念のためフォルダの中身をご確認ください。")
        pause_and_exit()
        return

    print(f"\n✅ 完了しました。{count} 件の名前を変更しました。")
    pause_and_exit()


def int_or(value: str, default: int) -> int:
    """文字を整数に変える。できなければ default を返す。"""
    try:
        return int(value)
    except (ValueError, TypeError):
        return default


def pause_and_exit():
    """ダブルクリックで開いたとき、画面がすぐ閉じないように一度待つ。"""
    try:
        input("\nEnterキーで終了します…")
    except EOFError:
        pass


if __name__ == "__main__":
    main()
