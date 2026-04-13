#!/usr/bin/env bash
set -euo pipefail

safe_deb_root=/safedebs

if [[ ! -d "$safe_deb_root" ]]; then
  echo "No safe debs mounted at $safe_deb_root; skipping installation."
  exit 0
fi

shopt -s nullglob
debs=("$safe_deb_root"/*.deb)
if ((${#debs[@]} == 0)); then
  echo "No safe debs found in $safe_deb_root; skipping installation."
  exit 0
fi

echo "Installing safe debs from $safe_deb_root"
dpkg -i "${debs[@]}"
