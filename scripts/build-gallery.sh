#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PY'
import json
import os
import subprocess
from pathlib import Path

project_root = Path.cwd()
gallery_dir = project_root / "gallery"
preview_root = project_root / "gallery_previews"
output_file = project_root / "gallery.json"

image_exts = {
    ".jpg", ".jpeg", ".png", ".gif", ".webp", ".avif", ".bmp", ".tiff", ".tif", ".svg"
}

preview_exts = {".jpg", ".jpeg", ".png"}

max_long_edge = 2000
jpeg_quality = 80

if not gallery_dir.exists():
    raise SystemExit("gallery/ folder not found.")

preview_root.mkdir(exist_ok=True)

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

            preview_path = None
            if ext in preview_exts:
                candidate = preview_root / relative_path
                candidate.parent.mkdir(parents=True, exist_ok=True)

                source_mtime = file_path.stat().st_mtime
                needs_preview = not candidate.exists() or candidate.stat().st_mtime < source_mtime

                if needs_preview:
                    cmd = [
                        "/usr/bin/sips",
                        "-Z",
                        str(max_long_edge),
                    ]
                    if ext in {".jpg", ".jpeg"}:
                        cmd += ["-s", "formatOptions", str(jpeg_quality)]
                    cmd += ["--out", str(candidate), str(file_path)]
                    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

                if candidate.exists():
                    preview_path = str(Path("gallery_previews") / relative_path).replace(os.sep, "/")

            images.append({
                "src": str(Path("gallery") / relative_path).replace(os.sep, "/"),
                "preview": preview_path,
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
