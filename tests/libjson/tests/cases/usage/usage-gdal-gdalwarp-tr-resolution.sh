#!/usr/bin/env bash
# @testcase: usage-gdal-gdalwarp-tr-resolution
# @title: GDAL gdalwarp -tr resolution change
# @description: Reprojects a small GeoTIFF to itself with gdalwarp -tr forcing a coarser pixel resolution and verifies that gdalinfo -json reports a strictly smaller raster size than the source.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalwarp-tr-resolution"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# World-window 2x2 degree extent so we can reason about pixel size in degrees.
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/src.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/src.tif"

gdalinfo -json "$tmpdir/src.tif" >"$tmpdir/src.json"
src_w=$(jq -e '.size[0]' "$tmpdir/src.json")
src_h=$(jq -e '.size[1]' "$tmpdir/src.json")

# Target pixel size of 0.25 deg over a 2x2 deg extent => 8x8 raster, which is
# strictly smaller than the gdalicon source dimensions.
gdalwarp -t_srs EPSG:4326 -tr 0.25 0.25 \
  "$tmpdir/src.tif" "$tmpdir/dst.tif" >"$tmpdir/warp.log" 2>&1
validator_require_file "$tmpdir/dst.tif"

gdalinfo -json "$tmpdir/dst.tif" >"$tmpdir/out.json"
jq -e --argjson sw "$src_w" --argjson sh "$src_h" '
  .driverShortName == "GTiff"
  and .size[0] > 0
  and .size[1] > 0
  and .size[0] < $sw
  and .size[1] < $sh
' "$tmpdir/out.json"
