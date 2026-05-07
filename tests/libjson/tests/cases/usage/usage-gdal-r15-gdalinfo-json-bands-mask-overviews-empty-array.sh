#!/usr/bin/env bash
# @testcase: usage-gdal-r15-gdalinfo-json-bands-mask-overviews-empty-array
# @title: GDAL gdalinfo JSON .bands[0].mask.overviews is an empty array on the bundled icon
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted .bands[0].mask.overviews is an empty array, the documented default mask-overview list when no overviews have been built.
# @timeout: 180
# @tags: usage, gdal, json, bands, mask
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
  (.bands[0].mask.overviews | type == "array")
  and ((.bands[0].mask.overviews | length) == 0)
' "$tmpdir/out.json"
