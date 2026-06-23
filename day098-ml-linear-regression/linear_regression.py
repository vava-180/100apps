# -*- coding: utf-8 -*-
"""
ミニ機械学習デモ：線形回帰（Day 098 / Python・標準ライブラリのみ）

「勉強時間（時間）」から「テストの点数」を予想する、いちばん基本の機械学習
＝線形回帰（直線をデータに当てはめる）を、ライブラリを使わず手で計算します。

やること:
  1. 小さなデータ（勉強時間と点数の組）から、いちばん合う直線を求める
  2. その直線の式（点数 = 傾き × 勉強時間 + 切片）と、当てはまり具合（R²）を表示
  3. 勉強時間を入力すると、点数を予想する

機械学習の最小例なので、外部ライブラリもネット通信も使いません。
"""

import math

# 学習に使うデータ（勉強した時間, テストの点数）。これが「教師データ」。
DATA = [
    (1, 35),
    (2, 45),
    (3, 50),
    (4, 65),
    (5, 70),
    (6, 78),
    (7, 85),
    (8, 92),
]


def train(data: list[tuple[float, float]]) -> tuple[float, float, float]:
    """
    最小二乗法で、いちばん合う直線 y = a*x + b を求める。
    戻り値: (a=傾き, b=切片, r2=決定係数 R^2)
    """
    n = len(data)
    if n < 2:
        raise ValueError("データは2件以上必要です。")

    # データが数値で、NaNや無限大でないことを先に確かめる
    for x, y in data:
        if not isinstance(x, (int, float)) or not isinstance(y, (int, float)):
            raise ValueError("学習データは数値で入力してください。")
        if not math.isfinite(x) or not math.isfinite(y):
            raise ValueError("学習データに NaN や無限大は使えません。")

    xs = [p[0] for p in data]
    ys = [p[1] for p in data]
    mean_x = sum(xs) / n
    mean_y = sum(ys) / n

    # 傾き a = sum((x-mean_x)*(y-mean_y)) / sum((x-mean_x)^2)
    sxy = sum((x - mean_x) * (y - mean_y) for x, y in data)
    sxx = sum((x - mean_x) ** 2 for x in xs)
    if sxx == 0:
        # xが全部同じだと直線の傾きが決められない
        raise ValueError("勉強時間の値がすべて同じため、直線を引けません。")
    a = sxy / sxx
    b = mean_y - a * mean_x

    # 当てはまり具合 R^2 = 1 - 残差平方和 / 全体平方和（1に近いほどよく合っている）
    ss_res = sum((y - (a * x + b)) ** 2 for x, y in data)
    ss_tot = sum((y - mean_y) ** 2 for y in ys)
    if ss_tot == 0:
        # yが全部同じ。直線が完全に乗れば当てはまりは完璧(1)、そうでなければ0
        r2 = 1.0 if ss_res == 0 else 0.0
    else:
        r2 = 1 - ss_res / ss_tot

    return a, b, r2


def to_number(text: str):
    """入力文字を数値にする。数値でなければ None を返す。"""
    text = text.strip()
    if text == "":
        return None
    try:
        value = float(text)
    except ValueError:
        return None
    # 無限大やNaNは弾く
    if not math.isfinite(value):
        return None
    return value


def main():
    print("=== ミニ機械学習デモ：線形回帰（Day 098）===")
    print("勉強時間からテストの点数を予想します。\n")

    # 1) 学習（データに問題があれば、tracebackではなく短いメッセージで知らせる）
    try:
        a, b, r2 = train(DATA)
    except ValueError as e:
        print(f"学習できません: {e}")
        return
    print("学習に使ったデータ（勉強時間 → 点数）:")
    for x, y in DATA:
        print(f"  {x} 時間 → {y} 点")

    # 2) 学習結果の表示
    print("\n--- 学習結果 ---")
    print(f"求まった直線: 点数 = {a:.2f} × 勉強時間 + {b:.2f}")
    print(f"当てはまり具合 R^2（決定係数）: {r2:.3f} （1に近いほどよく合っている）")
    print(f"目安: 1時間勉強を増やすと、点数は約 {a:.1f} 点 上がる関係です。")

    # 3) 予想（対話）
    print("\n--- 予想してみる ---")
    print("勉強時間を入力すると点数を予想します（q で終了）。")
    while True:
        text = input("勉強時間（時間）> ").strip()
        if text.lower() in ("q", "quit", "exit"):
            print("終了します。")
            break
        value = to_number(text)
        if value is None:
            print("  数字を入力してください（例: 4.5）。")
            continue
        if value < 0:
            print("  0以上の数字を入力してください。")
            continue
        pred = a * value + b
        # 点数は0〜100の範囲に収めて表示（はみ出しは目安として注記）
        shown = min(100.0, max(0.0, pred))
        note = ""
        if pred != shown:
            note = "（※データの範囲外なので、あくまで目安です）"
        print(f"  予想点数: {shown:.1f} 点 {note}")


if __name__ == "__main__":
    main()
