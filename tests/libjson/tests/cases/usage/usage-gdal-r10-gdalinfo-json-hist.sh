#!/usr/bin/env bash
# @testcase: usage-gdal-r10-gdalinfo-json-hist
# @title: GDAL gdalinfo JSON histogram bucket count
# @description: Runs gdalinfo -json -hist against the bundled gdalicon raster and verifies the histograms section emitted via json-c is a non-empty array with a positive bucket count for the first band.
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

gdalinfo -json -hist "$tmpdir/icon.png" >"$tmpdir/out.json"
# GDAL's JSON histogram object exposes a "buckets" array; some GDAL versions
# also expose a separate count field. Assert on the array shape only, since
# that is what json-c serialises and is portable across GDAL revisions.
jq -e '
  .bands[0].histogram.buckets
  | (type == "array") and (length > 0)
  and (all(.[]; type == "number" and . >= 0))
' "$tmpdir/out.json"
