# -*- coding: utf-8 -*-
"""
GitHub Pages トップページ生成（リポジトリ直下 index.html を作る）

各 dayXXX フォルダを走査して、見やすいカード一覧のトップページを作ります。
- フォルダに index.html があるアプリ（ブラウザで動くもの）には「▶ デモ」ボタンを付け、
  クリックすると GitHub Pages 上でそのアプリが開きます。
- それ以外（Python / VBA / Flutter など）は「コード」ボタンで GitHub のフォルダを開きます。

使い方:
  python tools/build_pages_index.py
出力:
  リポジトリ直下に index.html（GitHub Pages のトップページ）
"""

import re
import sys
import html
from pathlib import Path
from urllib.parse import quote
from datetime import date

# このスクリプトは tools/ にあるので、1つ上がリポジトリ直下
ROOT = Path(__file__).resolve().parent.parent
# このリポジトリ専用の固定値（fork時はここを書き換える）
REPO_URL = "https://github.com/vava-180/100apps"

DAY_DIR = re.compile(r"^day(\d+)-(.+)$", re.IGNORECASE)
IGNORE_DIRS = {"note_object", "0_note_object", "tools"}

PHASES = [
    (1, 20, "フェーズ1", "ブラウザツール（HTML / CSS / JS）"),
    (21, 40, "フェーズ2", "実務ツール（Python）"),
    (41, 65, "フェーズ3", "Office自動化（VBA）"),
    (66, 90, "フェーズ4", "スマホアプリ（Flutter）"),
    (91, 100, "フェーズ5", "集大成"),
    (101, 9999, "おまけ・拡張", "100日達成後の追加アプリ"),
]


def read_title(folder: Path, day_num: int, slug: str) -> str:
    """README.md の大見出し(H1)から「Day NNN:」を除いたタイトルを返す。"""
    readme = folder / "README.md"
    if readme.exists():
        try:
            for line in readme.read_text(encoding="utf-8-sig").splitlines():
                m = re.match(r"^#\s+(.+)$", line.strip())
                if m:
                    title = m.group(1).strip()
                    title = re.sub(r"^Day\s*\d+\s*[:：]\s*", "", title)
                    title = re.sub(r"\s*[／/・]\s*完\s*$", "", title)
                    return title
        except (OSError, UnicodeError):
            pass
    return slug


def collect_apps(base: Path) -> list[dict]:
    """dayXXX フォルダを集めて、番号順の一覧にする。"""
    apps = []
    for entry in base.iterdir():
        if not entry.is_dir() or entry.name in IGNORE_DIRS:
            continue
        m = DAY_DIR.match(entry.name)
        if not m:
            continue
        day_num = int(m.group(1))
        if day_num < 1:
            continue
        has_demo = (entry / "index.html").exists()
        apps.append({
            "num": day_num,
            "folder": entry.name,
            "title": read_title(entry, day_num, m.group(2)),
            "demo": has_demo,
        })
    apps.sort(key=lambda a: (a["num"], a["folder"].lower()))
    return apps


def card_html(app: dict) -> str:
    """1アプリ分のカードHTMLを作る。"""
    title = html.escape(app["title"])
    folder = app["folder"]
    day_label = f"Day {app['num']:03d}"
    # URLのパス部品としてエンコード（/ もエスケープするよう safe="" を明示）
    encoded = quote(folder, safe="")
    # デモ用は Pages 上の相対リンク、コード用は GitHub のフォルダURL
    demo_href = html.escape(f"{encoded}/index.html", quote=True)
    code_href = html.escape(f"{REPO_URL}/tree/main/{encoded}", quote=True)

    buttons = ""
    if app["demo"]:
        buttons += f'<a class="btn demo" href="{demo_href}">▶ デモ</a>'
    buttons += f'<a class="btn code" href="{code_href}" target="_blank" rel="noopener noreferrer">&lt;/&gt; コード</a>'

    badge = "demo" if app["demo"] else "code-only"
    return (
        f'<li class="card {badge}">'
        f'<div class="day">{day_label}</div>'
        f'<div class="title">{title}</div>'
        f'<div class="actions">{buttons}</div>'
        f'</li>'
    )


def build_html(apps: list[dict]) -> str:
    demo_count = sum(1 for a in apps if a["demo"])
    sections = []
    for start, end, name, desc in PHASES:
        group = [a for a in apps if start <= a["num"] <= end]
        if not group:
            continue
        cards = "\n".join(card_html(a) for a in group)
        sections.append(
            f'<section class="phase">\n'
            f'  <h2>{html.escape(name)} <small>{html.escape(desc)}・{len(group)}本</small></h2>\n'
            f'  <ul class="grid">\n{cards}\n  </ul>\n'
            f'</section>'
        )
    body = "\n".join(sections)
    today = date.today().isoformat()

    return f"""<!DOCTYPE html>
<html lang="ja">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>100日100アプリチャレンジ</title>
<style>
  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{ font-family: "Segoe UI","Hiragino Kaku Gothic ProN","Meiryo",sans-serif; color:#111827; background:#f3f4f6; line-height:1.6; }}
  a {{ text-decoration: none; }}
  .hero {{ background: linear-gradient(135deg,#4f46e5,#0e7490); color:#fff; text-align:center; padding:64px 20px; }}
  .hero h1 {{ font-size: 2rem; }}
  .hero p {{ margin-top:8px; opacity:.95; }}
  .hero .stats {{ margin-top:18px; display:flex; gap:28px; justify-content:center; flex-wrap:wrap; }}
  .hero .stats b {{ font-size:1.6rem; display:block; }}
  .hero .links {{ margin-top:20px; }}
  .hero .links a {{ display:inline-block; margin:4px; padding:9px 18px; border-radius:999px; background:rgba(255,255,255,.18); color:#fff; border:1px solid rgba(255,255,255,.5); font-weight:600; }}
  .hero .links a:hover {{ background:rgba(255,255,255,.3); }}
  main {{ max-width: 1000px; margin:0 auto; padding: 32px 16px 60px; }}
  .phase {{ margin-bottom: 36px; }}
  .phase h2 {{ font-size:1.2rem; color:#4f46e5; border-bottom:2px solid #e5e7eb; padding-bottom:8px; margin-bottom:16px; }}
  .phase h2 small {{ color:#6b7280; font-weight:normal; font-size:.82rem; }}
  .grid {{ list-style:none; display:grid; grid-template-columns:repeat(auto-fill,minmax(230px,1fr)); gap:14px; }}
  .card {{ background:#fff; border:1px solid #eee; border-radius:12px; padding:16px; display:flex; flex-direction:column; gap:8px; transition:transform .12s, box-shadow .12s; }}
  .card:hover {{ transform:translateY(-3px); box-shadow:0 8px 18px rgba(0,0,0,.08); }}
  .card .day {{ font-size:.75rem; font-weight:700; color:#0e7490; }}
  .card .title {{ font-size:1rem; font-weight:600; flex:1; }}
  .card .actions {{ display:flex; gap:8px; flex-wrap:wrap; }}
  .btn {{ font-size:.82rem; font-weight:700; padding:7px 12px; border-radius:8px; }}
  .btn.demo {{ background:#4f46e5; color:#fff; }}
  .btn.demo:hover {{ opacity:.9; }}
  .btn.code {{ background:#f3f4f6; color:#374151; border:1px solid #d1d5db; }}
  .btn.code:hover {{ background:#e5e7eb; }}
  footer {{ text-align:center; color:#9ca3af; font-size:.85rem; padding:24px; }}
</style>
</head>
<body>
<div class="hero">
  <h1>🚀 100日100アプリチャレンジ</h1>
  <p>IT初心者が、毎日ひとつアプリを作り続けた記録</p>
  <div class="stats">
    <div><b>{len(apps)}</b>作ったアプリ</div>
    <div><b>{demo_count}</b>ブラウザで試せる</div>
    <div><b>5</b>技術フェーズ</div>
  </div>
  <div class="links">
    <a href="day100-finale/index.html">🎉 総集編</a>
    <a href="day097-100apps-index/index.html">📚 記録サイト</a>
    <a href="{html.escape(REPO_URL, quote=True)}" target="_blank" rel="noopener noreferrer">💻 GitHub</a>
  </div>
</div>
<main>
{body}
</main>
<footer>
  「▶ デモ」はブラウザでそのまま動くアプリ。「&lt;/&gt; コード」はGitHubでソースを表示します。<br>
  自動生成: tools/build_pages_index.py ・ 更新日 {today}
</footer>
</body>
</html>
"""


def main():
    # Windowsのコンソール（cp932）で出せない文字があっても落ちないようにする
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(errors="backslashreplace")
    apps = collect_apps(ROOT)
    if not apps:
        print("dayXXX フォルダが見つかりませんでした。")
        return
    out = ROOT / "index.html"
    out.write_text(build_html(apps), encoding="utf-8")
    demo = sum(1 for a in apps if a["demo"])
    print(f"トップページを作成しました（{len(apps)}本 / うちデモ可 {demo}本）")
    print(f"  出力: {out}")


if __name__ == "__main__":
    main()
