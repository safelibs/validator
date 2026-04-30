#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-stats-mm
# @title: GDAL gdalinfo JSON stats min max
# @description: Runs gdalinfo -json -mm against the bundled sample raster and verifies a computedMin entry is reported in the JSON band metadata.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-json-stats-mm"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"
gdalinfo -json -mm "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '.bands[0] | has("computedMin") and has("computedMax")' "$tmpdir/out.json"
jq -e '.bands[0].computedMax >= .bands[0].computedMin' "$tmpdir/out.json"
