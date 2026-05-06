#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-band-blocks
# @title: GDAL gdalinfo -json band block size
# @description: Builds a small GTiff via gdal_translate then verifies gdalinfo -json reports a positive band block size for band 1.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.pgm" <<'PY'
import sys
w, h = 32, 32
with open(sys.argv[1], "wb") as f:
    f.write(f"P5\n{w} {h}\n255\n".encode())
    f.write(bytes((x ^ y) & 0xff for y in range(h) for x in range(w)))
PY

gdal_translate -of GTiff "$tmpdir/in.pgm" "$tmpdir/out.tif" >/dev/null
gdalinfo -json "$tmpdir/out.tif" >"$tmpdir/info.json"

python3 - "$tmpdir/info.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
bands = d.get("bands", [])
if not bands:
    raise SystemExit(f"no bands, keys {list(d)}")
block = bands[0].get("block")
if not block or len(block) != 2:
    raise SystemExit(f"bad block: {block!r}")
bx, by = block
if not (bx > 0 and by > 0):
    raise SystemExit(f"non-positive block dims: {block!r}")
PY
