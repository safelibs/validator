#!/usr/bin/env bash
# @testcase: usage-gdal-gdalwarp-multi-flag
# @title: GDAL gdalwarp -multi flag accepted
# @description: Reprojects a small GeoTIFF to EPSG:3857 with gdalwarp run in multi-threaded mode (-multi) and verifies the output raster is produced and gdalinfo -json reports the EPSG:3857 authority on the resulting CRS.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalwarp-multi-flag"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/src.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/src.tif"

gdalwarp -multi -t_srs EPSG:3857 \
  "$tmpdir/src.tif" "$tmpdir/dst.tif" >"$tmpdir/warp.log" 2>&1
validator_require_file "$tmpdir/dst.tif"

gdalinfo -json "$tmpdir/dst.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and .size[0] > 0
  and .size[1] > 0
  and (
    [.. | objects]
    | any(
        .;
        (.authority? == "EPSG" and ((.code? // empty) | tostring) == "3857")
        or (.id? | (.authority? == "EPSG" and ((.code? // empty) | tostring) == "3857"))
      )
  )
' "$tmpdir/out.json" || {
  # Fallback: explicit gdalsrsinfo authority lookup.
  gdalsrsinfo -o epsg "$tmpdir/dst.tif" | tee "$tmpdir/srs.epsg"
  grep -q 'EPSG:3857' "$tmpdir/srs.epsg"
}
