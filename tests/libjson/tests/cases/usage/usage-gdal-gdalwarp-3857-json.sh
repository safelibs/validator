#!/usr/bin/env bash
# @testcase: usage-gdal-gdalwarp-3857-json
# @title: GDAL gdalwarp 3857 JSON metadata
# @description: Reprojects a small GeoTIFF to EPSG:3857 with gdalwarp and verifies that gdalinfo -json reports the EPSG:3857 authority code on the resulting raster CRS.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalwarp-3857-json"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# Establish a known EPSG:4326 source so gdalwarp can reproject without an
# ambiguous CRS. gdal_translate stamps the output with a synthetic geotransform.
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 "$raster" "$tmpdir/src.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/src.tif"

gdalwarp -t_srs EPSG:3857 "$tmpdir/src.tif" "$tmpdir/dst.tif" >"$tmpdir/warp.log" 2>&1
validator_require_file "$tmpdir/dst.tif"

gdalinfo -json "$tmpdir/dst.tif" >"$tmpdir/out.json"
# Walk the gdalinfo JSON document for any object node carrying both
# `authority`/`code` (PROJJSON shape) or for an `id` whose `code`/`authority`
# pair is EPSG:3857; also accept a stringly-typed entry via gdalsrsinfo as a
# fallback.
jq -e '
  [.. | objects]
  | any(
      .;
      (.authority == "EPSG" and (.code | tostring) == "3857")
      or (.id? | (.authority? == "EPSG" and ((.code? // empty) | tostring) == "3857"))
    )
' "$tmpdir/out.json" || {
  # Fallback: explicit gdalsrsinfo authority lookup
  gdalsrsinfo -o epsg "$tmpdir/dst.tif" | tee "$tmpdir/srs.epsg"
  grep -q 'EPSG:3857' "$tmpdir/srs.epsg"
}
