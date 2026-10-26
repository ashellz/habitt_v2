# Habitt website

Static landing page, deployed to GitHub Pages at https://ashellz.github.io/habitt_v2/ by `.github/workflows/pages.yml` on every push to `main` that touches `website/`, `privacy.md` or `tos.md`.

- `index.html`, `assets/` — the page itself. No build step, no frameworks, no third-party requests (fonts are self-hosted Satoshi from `assets/new-fonts`).
- `build.py` — copies this folder into `_site/` and renders the repo's `privacy.md` and `tos.md` into `privacy.html` and `tos.html` (the App Store links to those URLs, so keep them).
- `assets/img/screens/` — real app screenshots (720px wide WebP), light and dark. `assets/img/og.png` is the social preview.

Preview locally:

```bash
python3 -m http.server 4173 --directory website
```

To render the legal pages too: `pip install markdown && python3 website/build.py` and serve `_site/` instead.

When moving to a custom domain, update the absolute URLs in `index.html` (canonical, og:url, og:image), `robots.txt` and `sitemap.xml`, and add a `CNAME` file.
