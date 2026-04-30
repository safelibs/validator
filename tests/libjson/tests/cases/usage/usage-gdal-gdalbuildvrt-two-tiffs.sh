#!/usr/bin/env bash
# @testcase: usage-gdal-gdalbuildvrt-two-tiffs
# @title: GDAL gdalbuildvrt over two GeoTIFFs
# @description: Builds a VRT mosaic over two synthetically georeferenced GeoTIFFs derived from gdalicon and verifies that gdalinfo -json reports the VRT driver and lists both source tiff files.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalbuildvrt-two-tiffs"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# Two side-by-side world-window tiles in EPSG:4326. Left tile covers x in
# [-2,0], right tile covers x in [0,2]; both span y in [-1,1].
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -2 1 0 -1 \
  "$raster" "$tmpdir/left.tif" >"$tmpdir/translate-left.log" 2>&1
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr 0 1 2 -1 \
  "$raster" "$tmpdir/right.tif" >"$tmpdir/translate-right.log" 2>&1
validator_require_file "$tmpdir/left.tif"
validator_require_file "$tmpdir/right.tif"

gdalbuildvrt "$tmpdir/mosaic.vrt" "$tmpdir/left.tif" "$tmpdir/right.tif" \
  >"$tmpdir/vrt.log" 2>&1
validator_require_file "$tmpdir/mosaic.vrt"

gdalinfo -json "$tmpdir/mosaic.vrt" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "VRT"
  and ((.files // []) | any(. | test("left\\.tif$")))
  and ((.files // []) | any(. | test("right\\.tif$")))
' "$tmpdir/out.json"
