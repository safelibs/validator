#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-lco-encoding-utf8
# @title: GDAL ogr2ogr CSV with -lco ENCODING=UTF-8
# @description: Exports a GeoJSON FeatureCollection containing non-ASCII property values to CSV with ogr2ogr -lco ENCODING=UTF-8 and -lco GEOMETRY=AS_WKT, verifying the produced CSV preserves the UTF-8 bytes and emits POINT WKT geometry.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-lco-encoding-utf8"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
# Property values include U+00E9 (LATIN SMALL LETTER E WITH ACUTE) and
# U+1F30D (EARTH GLOBE) to exercise multi-byte UTF-8 round-tripping.
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"café","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"🌍","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogr2ogr -f CSV "$tmpdir/csv" "$geojson" \
  -lco GEOMETRY=AS_WKT -lco ENCODING=UTF-8 >"$tmpdir/ogr2ogr.log" 2>&1

csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
validator_require_file "$csv"

# The accented "café" must survive verbatim as UTF-8 bytes.
validator_assert_contains "$csv" 'café'
validator_assert_contains "$csv" 'POINT'

# `file` should classify the output as UTF-8 (or at least not pure ASCII).
file "$csv" >"$tmpdir/file.txt"
grep -E 'UTF-8|Unicode|UTF8' "$tmpdir/file.txt" >/dev/null || {
  printf 'expected UTF-8 classification, got: %s\n' "$(cat "$tmpdir/file.txt")" >&2
  exit 1
}
