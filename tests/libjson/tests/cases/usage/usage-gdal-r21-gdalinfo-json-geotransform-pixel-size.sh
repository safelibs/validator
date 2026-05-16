#!/usr/bin/env bash
# @testcase: usage-gdal-r21-gdalinfo-json-geotransform-pixel-size
# @title: GDAL gdalinfo -json geoTransform pixel size matches a_ullr extent
# @description: Creates an 8x8 GTiff anchored at a known ullr extent (-10,10,10,-10) and asserts the json-c-emitted .geoTransform[1] equals 2.5 (positive x pixel size) and .geoTransform[5] equals -2.5 (negative y pixel size), pinning the array-of-six affine layout.
# @timeout: 120
# @tags: usage, gdal, gdalinfo, geotransform, r21
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdal_create -of GTiff -outsize 8 8 -bands 1 -ot Byte -a_srs EPSG:4326 \
  -a_ullr -10 10 10 -10 "$tmpdir/in.tif" >/dev/null

gdalinfo -json "$tmpdir/in.tif" >"$tmpdir/out.json"
python3 - "$tmpdir/out.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
gt = d["geoTransform"]
assert isinstance(gt, list) and len(gt) == 6, gt
assert abs(gt[1] - 2.5) < 1e-9, gt[1]
assert abs(gt[5] - (-2.5)) < 1e-9, gt[5]
PY
