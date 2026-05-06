#!/usr/bin/env bash
# @testcase: usage-pngquant-r9-ext-suffix-output
# @title: pngquant --ext custom suffix output naming
# @description: Runs pngquant with a custom --ext suffix and verifies the resulting file is created at the suffixed path while the input remains.
# @timeout: 180
# @tags: usage, image, png
# @client: pngquant

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/src.png" <<'PY'
import sys
from PIL import Image
img = Image.new("RGBA", (16, 16), (10, 200, 60, 255))
img.save(sys.argv[1], "PNG")
PY

pngquant --ext '-r9.png' --force 256 "$tmpdir/src.png"

[[ -f "$tmpdir/src-r9.png" ]] || { ls "$tmpdir" >&2; printf 'missing suffixed file\n' >&2; exit 1; }
[[ -f "$tmpdir/src.png" ]] || { printf 'original file disappeared\n' >&2; exit 1; }

file "$tmpdir/src-r9.png" >"$tmpdir/file.txt"
validator_assert_contains "$tmpdir/file.txt" 'PNG image data'
