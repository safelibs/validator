#!/usr/bin/env bash
# @testcase: usage-gdal-r14-gdalinfo-json-band-block-32x32-shape
# @title: GDAL gdalinfo JSON .bands[0].block components are positive on a tiled GTiff
# @description: Translates the bundled gdalicon PNG to a tiled GeoTIFF and verifies gdalinfo -json (json-c serialised) reports a .bands[0].block array of exactly two positive numeric entries, confirming the documented per-band block dimension shape on a tiled output.
# @timeout: 180
# @tags: usage, gdal, json, bands
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -co TILED=YES -co BLOCKXSIZE=16 -co BLOCKYSIZE=16 \
  "$raster" "$tmpdir/tiled.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/tiled.tif"

gdalinfo -json "$tmpdir/tiled.tif" >"$tmpdir/out.json"
jq -e '
  (.bands[0].block | type == "array")
  and (.bands[0].block | length == 2)
  and (.bands[0].block | all(type == "number" and . > 0))
  and (.bands[0].block == [16, 16])
' "$tmpdir/out.json"
