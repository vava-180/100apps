# -*- coding: utf-8 -*-
"""
100apps 記録サイト 自動生成（Day 097 / Python）

プロジェクト直下の「dayXXX-アプリ名」フォルダを全部さがして、
各 README.md の見出しからタイトルを読み取り、フェーズ別にならべた
一覧ページ（index.html）を自動で作ります。

使い方:
  python generate_site.py            ← プロジェクト直下を対象に生成
  python generate_site.py 対象フォルダ ← 対象を指定して生成

出力:
  このスクリプトと同じフォルダに index.html を作ります。
"""

import re
import sys
import html
from datetime import date
from pathlib import Path
from urllib.parse import quote

# フォルダ名の形「day001-character-counter」を読み取る正規表現
DAY_DIR = re.compile(r"^day(\d+)-(.+)$", re.IGNORECASE)

# 見ないフォルダ（ルール: note_object 系は触らない）
IGNORE_DIRS = {"note_object", "0_note_object"}

# フェーズの区切り（番号の範囲とラベル）
PHASES = [
    (1, 20, "フェーズ1：ブラウザツール（HTML/CSS/JS）"),
    (21, 40, "フェーズ2：実務ツール（Python）"),
    (41, 65, "フェーズ3：Office自動化（VBA）"),
    (66, 90, "フェーズ4：スマホアプリ（Flutter）"),
    (91, 100, "フェーズ5：集大成"),
]


def read_title(folder: Path, day_num: int, slug: str) -> str:
    """README.md の最初の見出し（# ...）をタイトルとして返す。無ければ代わりの名前。"""
    readme = folder / "README.md"
    if readme.exists():
        try:
            # utf-8-sig はBOM付きUTF-8も読める。読めない/壊れている時は下の代替名へ
            for line in readme.read_text(encoding="utf-8-sig").splitlines():
                # 「# タイトル」= Markdownの大見出し(H1)だけをタイトルにする
                m = re.match(r"^#\s+(.+)$", line.strip())
                if m:
                    return m.group(1).strip()
        except (OSError, UnicodeError):
            pass
    # READMEが無い/読めないときは、番号とフォルダ名から仮のタイトルを作る
    return f"Day {day_num:03d}: {slug}"


def find_link(folder: Path) -> str:
    """アプリへのリンク先を決める（index.html があればそれ、無ければ README.md）。"""
    if (folder / "index.html").exists():
        return "index.html"
    if (folder / "README.md").exists():
        return "README.md"
    return ""  # どちらも無ければフォルダ自体へのリンクにする


def collect_apps(base: Path) -> list[dict]:
    """対象フォルダ直下から、dayXXX フォルダを集めて情報の一覧にする。"""
    apps = []
    for entry in base.iterdir():
        if not entry.is_dir():
            continue
        if entry.name in IGNORE_DIRS:
            continue
        m = DAY_DIR.match(entry.name)
        if not m:
            continue
        day_num = int(m.group(1))
        # チャレンジは Day 1〜100。範囲外（day101 など）は一覧に出さない
        if not (1 <= day_num <= 100):
            continue
        slug = m.group(2)
        apps.append({
            "num": day_num,
            "folder": entry.name,
            "title": read_title(entry, day_num, slug),
            "link": find_link(entry),
        })
    # 番号順にならべる（同じ番号があってもフォルダ名で順番が安定する）
    apps.sort(key=lambda a: (a["num"], a["folder"].lower()))
    return apps


def build_html(apps: list[dict]) -> str:
    """集めたアプリ情報から、一覧ページのHTML文字列を組み立てる。"""
    done = len(apps)
    cards_by_phase = []

    for start, end, label in PHASES:
        group = [a for a in apps if start <= a["num"] <= end]
        if not group:
            continue
        items = []
        for a in group:
            # 画面に出す文字（タイトル）はHTMLエスケープする
            title = html.escape(a["title"])
            # リンク先は「URL用エンコード→属性用エスケープ」の順。二重エスケープを避ける
            folder_url = quote(a["folder"])
            link_url = quote(a["link"]) if a["link"] else ""
            href = "../" + folder_url + ("/" + link_url if link_url else "/")
            href = html.escape(href, quote=True)
            items.append(
                f'      <a class="card" href="{href}">'
                f'<span class="num">Day {a["num"]:03d}</span>'
                f'<span class="title">{title}</span></a>'
            )
        cards_by_phase.append(
            f'    <section>\n      <h2>{html.escape(label)} '
            f'<small>（{len(group)}本）</small></h2>\n'
            f'      <div class="grid">\n' + "\n".join(items) + "\n      </div>\n    </section>"
        )

    sections = "\n".join(cards_by_phase)
    today = date.today().isoformat()

    return f"""<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>100apps 記録サイト</title>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{ font-family: "Segoe UI", "Meiryo", sans-serif; color: #111827; background: #f3f4f6; }}
  header {{ background: linear-gradient(135deg,#4f46e5,#06b6d4); color:#fff; text-align:center; padding:56px 20px; }}
  header h1 {{ font-size: 2rem; }}
  header p {{ margin-top: 8px; opacity: .95; }}
  main {{ max-width: 960px; margin: 0 auto; padding: 32px 20px; }}
  section {{ margin-bottom: 36px; }}
  h2 {{ font-size: 1.2rem; color:#4f46e5; border-bottom: 2px solid #e5e7eb; padding-bottom: 6px; margin-bottom: 16px; }}
  h2 small {{ color:#6b7280; font-weight: normal; font-size: .85rem; }}
  .grid {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(220px,1fr)); gap: 12px; }}
  .card {{ display:flex; flex-direction:column; gap:4px; background:#fff; border:1px solid #eee;
          border-radius:10px; padding:14px; text-decoration:none; color:#111827; transition:transform .12s; }}
  .card:hover {{ transform: translateY(-3px); box-shadow: 0 6px 16px rgba(0,0,0,.08); }}
  .num {{ font-size:.78rem; font-weight:700; color:#06b6d4; }}
  .title {{ font-size:.95rem; }}
  footer {{ text-align:center; color:#9ca3af; font-size:.85rem; padding:24px; }}
</style>
</head>
<body>
<header>
  <h1>100apps 記録サイト</h1>
  <p>100日100アプリチャレンジの全作品一覧（自動生成）</p>
  <p>現在 {done} / 100 本　更新日: {today}</p>
</header>
<main>
{sections}
</main>
<footer>このページは generate_site.py で自動生成されました ・ Day 097 / 100</footer>
</body>
</html>
"""


def main():
    # 対象フォルダ：引数があればそれ、無ければ「このスクリプトの1つ上（プロジェクト直下）」
    if len(sys.argv) >= 2:
        base = Path(sys.argv[1].strip().strip('"').strip("'"))
    else:
        base = Path(__file__).resolve().parent.parent

    if not base.is_dir():
        print(f"フォルダが見つかりません: {base}")
        return

    apps = collect_apps(base)
    if not apps:
        print("dayXXX フォルダが見つかりませんでした。")
        return

    out_path = Path(__file__).resolve().parent / "index.html"
    html_text = build_html(apps)
    out_path.write_text(html_text, encoding="utf-8")

    print(f"一覧を作成しました（{len(apps)} 本）")
    print(f"  出力: {out_path}")
    print("  ブラウザで index.html を開くと一覧が見られます。")


if __name__ == "__main__":
    main()
