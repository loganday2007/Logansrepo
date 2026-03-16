#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PY'
import json
import os
from pathlib import Path

project_root = Path.cwd()
gallery_dir = project_root / "gallery"
output_file = project_root / "gallery.json"

image_exts = {
    ".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif", ".bmp", ".tiff", ".tif", ".svg"
}

if not gallery_dir.exists():
    raise SystemExit("gallery/ folder not found.")

sections = []

for entry in sorted(gallery_dir.iterdir()):
    if not entry.is_dir():
        continue
    section_name = entry.name
    images = []
    folders = set()

    for root, _, files in os.walk(entry):
        for fname in files:
            ext = Path(fname).suffix.lower()
            if ext not in image_exts:
                continue
            file_path = Path(root) / fname
            relative_path = file_path.relative_to(gallery_dir)
            relative_dir = relative_path.parent
            if relative_dir.parts:
                folders.add(relative_dir.parts[0])
            images.append({
                "src": str(Path("gallery") / relative_path).replace(os.sep, "/"),
                "name": fname,
                "path": str(relative_path).replace(os.sep, "/"),
            })

    sections.append({
        "name": section_name,
        "folders": sorted(folders),
        "images": images,
    })

output = {
    "generatedAt": "",
    "sections": sections,
}

output_file.write_text(json.dumps(output, indent=2))
print(f"Generated {output_file}")
PY
