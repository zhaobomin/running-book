#!/usr/bin/env bash
set -euo pipefail

echo "[check] empty headings"
grep -R "^#\s*$" -n docs/ || true

echo "[check] leftover TODO"
grep -R "TODO" -n docs/ || true

echo "[check] repeated disclaimer count (rough)"
grep -R "非医疗建议" -n docs/ | wc -l || true