#!/usr/bin/env bash
# @testcase: usage-gdal-r10-gdalinfo-json-approx-stats
# @title: GDAL gdalinfo JSON approximate band statistics
# @description: Runs gdalinfo -json -approx_stats against the bundled gdalicon raster and verifies the band metadata emitted via json-c carries minimum, maximum, mean and stdDev keys with consistent numeric ordering.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json -approx_stats "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '
  .bands[0]
  | has("minimum") and has("maximum") and has("mean") and has("stdDev")
  and (.minimum | type == "number")
  and (.maximum | type == "number")
  and (.maximum >= .minimum)
  and (.stdDev | type == "number")
  and (.stdDev >= 0)
' "$tmpdir/out.json"
