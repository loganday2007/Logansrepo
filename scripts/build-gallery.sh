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

preview_sizes = [800, 1400, 2000]
preview_quality = 80

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
            srcset_entries = []

            if ext in preview_exts:
                source_mtime = file_path.stat().st_mtime
                for size in preview_sizes:
                    target_path = preview_root / str(size) / relative_path
                    target_path.parent.mkdir(parents=True, exist_ok=True)

                    needs_preview = not target_path.exists() or target_path.stat().st_mtime < source_mtime

                    if needs_preview:
                        cmd = [
                            "/usr/bin/sips",
                            "-Z",
                            str(size),
                        ]
                        if ext in {".jpg", ".jpeg"}:
                            cmd += ["-s", "formatOptions", str(preview_quality)]
                        cmd += ["--out", str(target_path), str(file_path)]
                        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

                    if target_path.exists():
                        src = str(Path("gallery_previews") / str(size) / relative_path).replace(os.sep, "/")
                        srcset_entries.append({"src": src, "w": size})

                if srcset_entries:
                    preview_path = srcset_entries[-1]["src"]

            images.append({
                "src": str(Path("gallery") / relative_path).replace(os.sep, "/"),
                "preview": preview_path,
                "srcset": srcset_entries,
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
