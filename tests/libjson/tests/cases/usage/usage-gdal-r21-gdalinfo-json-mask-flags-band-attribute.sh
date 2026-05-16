#!/usr/bin/env bash
# @testcase: usage-gdal-r21-gdalinfo-json-mask-flags-band-attribute
# @title: GDAL gdalinfo -json bands entries have a "band" integer attribute starting at 1
# @description: Creates a three-band Byte GTiff, runs gdalinfo -json, and asserts each json-c-emitted .bands[] entry has a "band" integer attribute and that the numbering is exactly [1,2,3], pinning 1-based band indexing in the multi-band JSON shape.
# @timeout: 120
# @tags: usage, gdal, gdalinfo, bands, indexing, r21
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdal_create -of GTiff -outsize 6 6 -bands 3 -ot Byte "$tmpdir/in.tif" >/dev/null
gdalinfo -json "$tmpdir/in.tif" >"$tmpdir/out.json"
python3 - "$tmpdir/out.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
bands = d["bands"]
nums = [b["band"] for b in bands]
assert nums == [1, 2, 3], nums
PY
