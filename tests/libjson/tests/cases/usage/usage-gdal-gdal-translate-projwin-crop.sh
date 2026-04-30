#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-projwin-crop
# @title: GDAL gdal_translate -projwin crop
# @description: Stamps a synthetic geotransform on the gdalicon PNG and crops a sub-window with gdal_translate -projwin, verifying the cropped raster reports a strictly smaller pixel size than the source via gdalinfo -json.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-projwin-crop"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# Stamp a synthetic CRS+geotransform spanning (-1,-1)..(1,1) so projwin maps
# cleanly into the source pixel grid.
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/src.tif" >"$tmpdir/translate-src.log" 2>&1
validator_require_file "$tmpdir/src.tif"

gdalinfo -json "$tmpdir/src.tif" >"$tmpdir/src.json"
src_w=$(jq -e '.size[0]' "$tmpdir/src.json")
src_h=$(jq -e '.size[1]' "$tmpdir/src.json")

# Crop the central half of the world-window: ulx=-0.5 uly=0.5 lrx=0.5 lry=-0.5
gdal_translate -of GTiff -projwin -0.5 0.5 0.5 -0.5 \
  "$tmpdir/src.tif" "$tmpdir/crop.tif" >"$tmpdir/translate-crop.log" 2>&1
validator_require_file "$tmpdir/crop.tif"

gdalinfo -json "$tmpdir/crop.tif" >"$tmpdir/out.json"
jq -e --argjson sw "$src_w" --argjson sh "$src_h" '
  .driverShortName == "GTiff"
  and .size[0] > 0
  and .size[1] > 0
  and .size[0] < $sw
  and .size[1] < $sh
' "$tmpdir/out.json"
