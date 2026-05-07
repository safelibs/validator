#!/usr/bin/env bash
# @testcase: usage-gdal-r15-gdalinfo-json-bands-length-four-rgba
# @title: GDAL gdalinfo JSON .bands array has length 4 for the bundled RGBA icon
# @description: Runs gdalinfo -json on the bundled gdalicon RGBA PNG and verifies the json-c emitted .bands array has length exactly 4, the documented per-channel band count for the RGBA raster shipped with libgdal.
# @timeout: 180
# @tags: usage, gdal, json, bands
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '(.bands | type == "array") and (.bands | length == 4)' "$tmpdir/out.json"
