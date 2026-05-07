#!/usr/bin/env bash
# @testcase: usage-gdal-r13-gdalinfo-json-files-singleton-png
# @title: GDAL gdalinfo JSON .files reports exactly one path ending in .png
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted .files array has length exactly 1, confirming a single PNG dataset advertises only one underlying file.
# @timeout: 180
# @tags: usage, gdal, json, files
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
  (.files | type == "array")
  and (.files | length == 1)
  and (.files[0] | endswith(".png"))
' "$tmpdir/out.json"
