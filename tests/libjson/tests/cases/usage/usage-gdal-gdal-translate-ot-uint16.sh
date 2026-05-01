#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-ot-uint16
# @title: GDAL gdal_translate UInt16 conversion
# @description: Converts the bundled gdalicon PNG into a GeoTIFF with -ot UInt16, then verifies via gdalinfo -json that every band of the output reports type UInt16.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-ot-uint16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -ot UInt16 -of GTiff "$raster" "$tmpdir/u16.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/u16.tif"

gdalinfo -json "$tmpdir/u16.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and ((.bands | length) >= 1)
  and (all(.bands[]; .type == "UInt16"))
' "$tmpdir/out.json"
