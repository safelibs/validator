#!/usr/bin/env bash
# @testcase: usage-gdal-r11-gdalinfo-json-stac-raster-bands-uint8
# @title: GDAL gdalinfo JSON .stac.raster:bands data_type uint8 for PNG icon
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted .stac["raster:bands"] array reports data_type "uint8" for every band of the four-channel raster.
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
  (.stac["raster:bands"] | length == 4)
  and (.stac["raster:bands"] | all(.data_type == "uint8"))
' "$tmpdir/out.json"
