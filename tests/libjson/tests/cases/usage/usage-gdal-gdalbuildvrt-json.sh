#!/usr/bin/env bash
# @testcase: usage-gdal-gdalbuildvrt-json
# @title: GDAL gdalbuildvrt JSON metadata
# @description: Builds a VRT mosaic over a small raster fixture with gdalbuildvrt and verifies that gdalinfo -json reports the VRT driver and lists the underlying source file.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalbuildvrt-json"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# Stamp a synthetic CRS+geotransform so gdalbuildvrt accepts the input.
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 "$raster" "$tmpdir/icon.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/icon.tif"

gdalbuildvrt "$tmpdir/mosaic.vrt" "$tmpdir/icon.tif" >"$tmpdir/vrt.log" 2>&1
validator_require_file "$tmpdir/mosaic.vrt"

gdalinfo -json "$tmpdir/mosaic.vrt" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "VRT"
  and ((.files // []) | any(. | test("icon\\.tif$")))
' "$tmpdir/out.json"
