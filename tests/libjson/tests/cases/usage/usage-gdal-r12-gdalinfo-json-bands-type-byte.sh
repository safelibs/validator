#!/usr/bin/env bash
# @testcase: usage-gdal-r12-gdalinfo-json-bands-type-byte
# @title: GDAL gdalinfo JSON bands[].type is "Byte" for the gdalicon PNG
# @description: Runs gdalinfo -json on the bundled gdalicon RGBA PNG and verifies every entry of the json-c emitted .bands[].type field is the literal string "Byte".
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
jq -e '
  (.bands | length == 4)
  and (.bands | all(.type == "Byte"))
' "$tmpdir/out.json"
