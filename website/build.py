"""Builds the Habitt landing page into _site/ for GitHub Pages.

Copies website/ as-is and renders the repo's privacy.md and tos.md into
styled privacy.html and tos.html, so the URLs the App Store links to keep
working. Needs the `markdown` package (pip install markdown).

    python website/build.py            # writes ./_site
    python website/build.py out_dir    # writes elsewhere
"""

import html
import shutil
import sys
from pathlib import Path

import markdown

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "website"
OUT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else ROOT / "_site"

LEGAL = [
    ("privacy.md", "privacy.html", "Privacy Policy"),
    ("tos.md", "tos.html", "Terms of Service"),
]

TEMPLATE = """<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{title} · Habitt</title>
  <meta name="description" content="{title} for Habitt, the private habit tracker.">
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="stylesheet" href="assets/css/style.css">
  <script>try{{var t=localStorage.getItem("habitt-theme");if(t)document.documentElement.setAttribute("data-theme",t)}}catch(e){{}}</script>
</head>
<body class="legal-page">
  <header class="legal-head">
    <div class="container">
      <a class="brand" href="./"><img src="assets/img/icon.png" alt="" width="36" height="36"><span>habitt</span></a>
      <a class="btn btn-ghost" href="./">Back to home</a>
    </div>
  </header>
  <main class="container legal">
    <span class="eyebrow">Legal</span>
    <h1>{title}</h1>
    {body}
  </main>
  <footer>
    <div class="container foot-bottom">
      <span>© ThinkingApp</span>
      <span><a href="privacy.html">Privacy</a> · <a href="tos.html">Terms</a></span>
    </div>
  </footer>
</body>
</html>
"""


def main():
    if OUT.exists():
        shutil.rmtree(OUT)
    shutil.copytree(SRC, OUT, ignore=shutil.ignore_patterns("build.py", "README.md", ".DS_Store"))

    for src_name, out_name, title in LEGAL:
        text = (ROOT / src_name).read_text(encoding="utf-8")
        body = markdown.markdown(text, extensions=["extra", "sane_lists"])
        page = TEMPLATE.format(title=html.escape(title), body=body)
        (OUT / out_name).write_text(page, encoding="utf-8")

    # Plain static files: skip Jekyll processing on Pages.
    (OUT / ".nojekyll").write_text("")
    print(f"Built site into {OUT}")


if __name__ == "__main__":
    main()
