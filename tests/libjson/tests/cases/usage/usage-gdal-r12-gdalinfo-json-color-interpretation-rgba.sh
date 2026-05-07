#!/usr/bin/env bash
# @testcase: usage-gdal-r12-gdalinfo-json-color-interpretation-rgba
# @title: GDAL gdalinfo JSON .bands[].colorInterpretation lists Red/Green/Blue/Alpha in order
# @description: Runs gdalinfo -json on the bundled gdalicon RGBA PNG and verifies the json-c emitted .bands[].colorInterpretation values are exactly Red, Green, Blue, Alpha in that order.
# @timeout: 180
# @tags: usage, gdal, json, color
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
  ([.bands[].colorInterpretation] == ["Red", "Green", "Blue", "Alpha"])
' "$tmpdir/out.json"
