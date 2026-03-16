#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

scripts/build-gallery.sh

git add .

if git diff --cached --quiet; then
  echo "No changes to commit."
  exit 0
fi

git commit -m "Update gallery"

git push
