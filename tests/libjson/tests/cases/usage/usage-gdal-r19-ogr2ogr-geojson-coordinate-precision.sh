#!/usr/bin/env bash
# @testcase: usage-gdal-r19-ogr2ogr-geojson-coordinate-precision
# @title: GDAL ogr2ogr -lco COORDINATE_PRECISION truncates emitted coordinate decimals
# @description: Converts a single-point GeoJSON to GeoJSON with -lco COORDINATE_PRECISION=2 and asserts the json-c serialiser emits the X coordinate as exactly two decimal places (1.23), pinning the precision-truncation layer-creation option.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, geojson, coordinate-precision, r19
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[1.234567,4.567891]}}
]}
JSON

ogr2ogr -f GeoJSON -lco COORDINATE_PRECISION=2 "$tmpdir/out.geojson" "$tmpdir/in.geojson"
validator_require_file "$tmpdir/out.geojson"

# The numeric value must be exactly 1.23 (truncated to 2 decimals)
jq -e '.features[0].geometry.coordinates[0] == 1.23' "$tmpdir/out.geojson" >/dev/null
jq -e '.features[0].geometry.coordinates[1] == 4.57' "$tmpdir/out.geojson" >/dev/null
