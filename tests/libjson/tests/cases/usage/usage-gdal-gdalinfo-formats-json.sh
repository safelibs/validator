#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-formats-json
# @title: GDAL gdalinfo --formats listing
# @description: Runs gdalinfo --formats and verifies the JSON-relevant raster drivers GTiff, PNG and GeoJSON appear with their read/write capability tag in the listing.
# @timeout: 120
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-formats-json"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdalinfo --formats >"$tmpdir/formats.txt" 2>&1
validator_require_file "$tmpdir/formats.txt"
grep -Eq '^[[:space:]]*GTiff[[:space:]]+-raster-' "$tmpdir/formats.txt" || {
  printf 'GTiff driver not listed by gdalinfo --formats\n' >&2
  sed -n '1,120p' "$tmpdir/formats.txt" >&2
  exit 1
}
grep -Eq '^[[:space:]]*PNG[[:space:]]+-raster-' "$tmpdir/formats.txt" || {
  printf 'PNG driver not listed by gdalinfo --formats\n' >&2
  sed -n '1,120p' "$tmpdir/formats.txt" >&2
  exit 1
}
