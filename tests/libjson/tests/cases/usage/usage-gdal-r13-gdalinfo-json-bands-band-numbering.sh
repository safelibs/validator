#!/usr/bin/env bash
# @testcase: usage-gdal-r13-gdalinfo-json-bands-band-numbering
# @title: GDAL gdalinfo JSON .bands[].band lists 1, 2, 3, 4 in order for the icon
# @description: Runs gdalinfo -json on the bundled gdalicon RGBA PNG and verifies the json-c emitted .bands[].band values form the contiguous sequence [1, 2, 3, 4], reflecting the documented one-based ordinal numbering of raster bands.
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
jq -e '[.bands[].band] == [1, 2, 3, 4]' "$tmpdir/out.json"
