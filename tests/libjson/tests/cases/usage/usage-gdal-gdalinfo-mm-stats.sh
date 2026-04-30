#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-mm-stats
# @title: GDAL gdalinfo -mm min/max
# @description: Computes per-band min/max with gdalinfo -mm on the bundled gdalicon raster and verifies the textual output reports a Computed Min/Max line for at least one band.
# @timeout: 180
# @tags: usage, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-mm-stats"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdalinfo -mm "$raster" >"$tmpdir/out.txt" 2>&1
validator_require_file "$tmpdir/out.txt"

validator_assert_contains "$tmpdir/out.txt" 'Computed Min/Max'
validator_assert_contains "$tmpdir/out.txt" 'Band 1'

# Cross-check via gdalinfo -json -mm: the JSON form should also expose
# computedMin/computedMax on at least one band.
gdalinfo -json -mm "$raster" >"$tmpdir/out.json"
jq -e '
  (.bands | length) >= 1
  and any(
    .bands[];
    (has("computedMin") and has("computedMax"))
    or (has("min") and has("max"))
  )
' "$tmpdir/out.json"
