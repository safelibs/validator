#!/usr/bin/env bash
# @testcase: usage-gdal-r15-gdalinfo-json-stac-raster-bands-length-four
# @title: GDAL gdalinfo JSON .stac["raster:bands"] has length 4 on the RGBA icon
# @description: Runs gdalinfo -json on the bundled gdalicon RGBA PNG and verifies the json-c emitted .stac["raster:bands"] array has length exactly 4 with each element carrying a string data_type, exercising the documented STAC raster:bands extension shape.
# @timeout: 180
# @tags: usage, gdal, json, stac
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '
  (.stac["raster:bands"] | type == "array")
  and ((.stac["raster:bands"] | length) == 4)
  and ([.stac["raster:bands"][].data_type] | all(type == "string"))
' "$tmpdir/out.json"
