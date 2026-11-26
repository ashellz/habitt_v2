#!/usr/bin/env bash
# Renders every store image in every language into marketing/store_images/out/.
set -euo pipefail
cd "$(dirname "$0")"
VENV="${VENV:-/tmp/store-images-venv}"
[ -x "$VENV/bin/python" ] || { python3 -m venv "$VENV" && "$VENV/bin/pip" install -q pillow numpy; }
"$VENV/bin/python" watch_composite.py
rm -f build/hidden.json build/baked.json
node render.mjs en            # English first: occlusion.py compares it with the original design
"$VENV/bin/python" occlusion.py
"$VENV/bin/python" baked.py      # English the Figma copy did not hide
node render.mjs               # all languages, covered layers skipped
"$VENV/bin/python" gallery.py           # out/index.html
