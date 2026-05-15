#!/usr/bin/env bash
# @testcase: usage-gdal-r20-gdalinfo-json-stdev-numeric
# @title: GDAL gdalinfo -json -stats reports a numeric stdDev for a uniform GTiff band
# @description: Builds a small uniform-value GeoTIFF via gdal_translate from an XYZ grid, runs gdalinfo -json -stats, and asserts the .bands[0].stdDev field is a JSON number (any numeric value) and the .bands[0].mean field is also numeric, pinning the json-c emitted numeric statistics shape.
# @timeout: 180
# @tags: usage, gdal, gdalinfo, json, stats, stdev, r20
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.xyz" <<'XYZ'
0 0 100
1 0 110
2 0 120
0 1 105
1 1 115
2 1 125
0 2 108
1 2 118
2 2 128
XYZ

gdal_translate -of GTiff "$tmpdir/in.xyz" "$tmpdir/out.tif" >/dev/null
gdalinfo -json -stats "$tmpdir/out.tif" >"$tmpdir/info.json"
validator_require_file "$tmpdir/info.json"

jq -e '(.bands[0].stdDev | type) == "number"' "$tmpdir/info.json" >/dev/null
jq -e '(.bands[0].mean | type) == "number"' "$tmpdir/info.json" >/dev/null
