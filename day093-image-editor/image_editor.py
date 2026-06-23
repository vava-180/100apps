# -*- coding: utf-8 -*-
"""
画像加工ツール（Day 093 / Python + Pillow）

フォルダの中の画像（または1枚）を、まとめて加工します。
できること:
  1. グレースケール（白黒）にする
  2. 幅を指定してリサイズ（縦横比はそのまま）
  3. 回転（90 / 180 / 270 度）

元の画像は上書きせず、入力フォルダの中に「kakou_出力」フォルダを作って保存します。

使い方:
  python image_editor.py            ← 対話形式（画面の質問に答える）
  python image_editor.py 画像フォルダ ← フォルダ/ファイルを直接指定

必要なもの: Pillow （未導入なら  pip install pillow  ）
"""

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow（画像ライブラリ）が見つかりません。")
    print("次のコマンドで入れてください:  pip install pillow")
    sys.exit(1)

# 加工できる画像の拡張子（小文字で比較する）
IMAGE_EXTS = {".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp"}


def safe_text(value: object) -> str:
    """画面に出せない文字（コンソールの文字コード外）を ? に置き換える。"""
    text = str(value)
    enc = sys.stdout.encoding or "utf-8"
    return text.encode(enc, errors="replace").decode(enc)


def say(message: str) -> None:
    """print の安全版。ファイル名などに変な文字があっても落ちない。"""
    print(safe_text(message))


def ask(prompt: str) -> str:
    """質問を表示して、前後の空白を取り除いた入力を返す。"""
    return input(prompt).strip()


def collect_images(target: Path) -> list[Path]:
    """対象（ファイル or フォルダ）から、画像ファイルの一覧を作る。"""
    if target.is_file():
        return [target] if target.suffix.lower() in IMAGE_EXTS else []
    # フォルダのときは直下だけを見る（サブフォルダは見ない＝想定外の巻き込み防止）
    files = [p for p in sorted(target.iterdir())
             if p.is_file() and p.suffix.lower() in IMAGE_EXTS]
    return files


def to_grayscale(img: Image.Image) -> Image.Image:
    """白黒（グレースケール）にする。"""
    return img.convert("L")


def resize_to_width(img: Image.Image, width: int) -> Image.Image:
    """幅を width にそろえ、高さは縦横比を保って自動で決める。"""
    w, h = img.size
    if w == 0:
        return img
    new_h = max(1, round(h * width / w))  # 高さが0にならないよう最低1
    # LANCZOS はきれいに縮小できる方法
    return img.resize((width, new_h), Image.Resampling.LANCZOS)


def rotate(img: Image.Image, degree: int) -> Image.Image:
    """時計回りに 90 / 180 / 270 度回転（画質を落とさない transpose を使う）。"""
    # Pillow の ROTATE_90 は「反時計回り90度」。時計回りに合わせるため入れ替える。
    table = {
        90: Image.Transpose.ROTATE_270,
        180: Image.Transpose.ROTATE_180,
        270: Image.Transpose.ROTATE_90,
    }
    return img.transpose(table[degree])


def save_image(img: Image.Image, src: Path, out_dir: Path) -> Path:
    """加工後の画像を、出力フォルダに元と同じファイル名で保存する。"""
    out_path = out_dir / src.name
    save_img = img
    ext = src.suffix.lower()
    # JPEG は RGB でないと保存できない/崩れることがあるので、RGB以外はRGBに直す
    if ext in {".jpg", ".jpeg"} and save_img.mode != "RGB":
        save_img = save_img.convert("RGB")
    save_img.save(out_path)
    return out_path


def choose_operation():
    """加工メニューを表示して、処理する関数を1つ返す。1〜3以外は聞き直す。"""
    while True:
        say("\nどの加工をしますか？")
        say("  1) グレースケール（白黒）")
        say("  2) 幅を指定してリサイズ")
        say("  3) 時計回りに回転（90 / 180 / 270 度）")
        choice = ask("番号を入力 > ")

        if choice == "1":
            return lambda img: to_grayscale(img), "グレースケール"

        if choice == "2":
            while True:
                w = ask("新しい幅（ピクセル、例: 800）> ")
                if w.isdigit() and int(w) > 0:
                    width = int(w)
                    return lambda img: resize_to_width(img, width), f"幅{width}pxにリサイズ"
                say("1以上の整数を入力してください。")

        if choice == "3":
            while True:
                d = ask("回転角度（時計回り。90 / 180 / 270）> ")
                if d in {"90", "180", "270"}:
                    degree = int(d)
                    return lambda img: rotate(img, degree), f"時計回り{degree}度回転"
                say("90 / 180 / 270 のいずれかを入力してください。")

        say("1〜3 の番号を入力してください。")


def main():
    say("=== 画像加工ツール（Day 093）===")

    # 入力パス：引数があればそれを、無ければ質問する
    if len(sys.argv) >= 2:
        raw = sys.argv[1]
    else:
        raw = ask("加工する画像のフォルダ（または画像ファイル）のパス > ")
    # Windowsで引用符付き（"C:\...\img.jpg"）で貼っても通るよう、前後の引用符を外す
    raw = raw.strip().strip('"').strip("'")
    if not raw:
        say("パスが入力されませんでした。終了します。")
        return

    target = Path(raw)
    if not target.exists():
        say(f"見つかりません: {target}")
        return

    images = collect_images(target)
    if not images:
        say("画像ファイル（jpg/png/gif/bmp/webp）が見つかりませんでした。")
        return
    say(f"対象の画像: {len(images)} 枚")

    op, op_name = choose_operation()
    if op is None:
        say("加工が選ばれませんでした。終了します。")
        return

    # 出力フォルダを作る（入力がファイルなら、その親フォルダの中に作る）
    base_dir = target if target.is_dir() else target.parent
    out_dir = base_dir / "kakou_出力"
    try:
        out_dir.mkdir(exist_ok=True)
    except OSError as e:
        say(f"出力フォルダを作れませんでした: {e}")
        return
    if not out_dir.is_dir():
        say(f"出力先がフォルダではありません: {out_dir}")
        return

    done, failed = 0, 0
    for src in images:
        try:
            with Image.open(src) as img:
                img.load()  # ファイルを今すぐ読み込む（with の外でも使えるように）
                result = op(img)
                out_path = save_image(result, src, out_dir)
            say(f"  OK: {src.name} -> {out_path.name}")
            done += 1
        except Exception as e:
            # 1枚が壊れていても、残りの処理は続ける
            say(f"  NG: {src.name} … 読み込み/保存に失敗（{e}）")
            failed += 1

    say(f"\n完了: {op_name}")
    say(f"  成功 {done} 枚 / 失敗 {failed} 枚")
    say(f"  保存先: {out_dir}")


if __name__ == "__main__":
    main()
