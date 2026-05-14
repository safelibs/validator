#!/usr/bin/env bash
# @testcase: usage-gdal-r18-ogr2ogr-geojson-to-csv-row-count
# @title: GDAL ogr2ogr GeoJSON to CSV preserves the 3 feature rows
# @description: Converts a 3-feature GeoJSON to CSV via ogr2ogr -f CSV and asserts the resulting CSV has exactly 3 data rows in addition to its header, locking the row-count fidelity of the json-c-driven feature iteration.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, csv, r18
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1,"name":"alpha"},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"id":2,"name":"beta"},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"id":3,"name":"gamma"},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f CSV "$tmpdir/out.csv" "$tmpdir/in.geojson"
validator_require_file "$tmpdir/out.csv"

# Skip the header row and count remaining non-empty lines.
data_rows=$(tail -n +2 "$tmpdir/out.csv" | grep -c .)
[[ "$data_rows" -eq 3 ]] || {
  printf 'expected 3 data rows, got %s\n' "$data_rows" >&2
  exit 1
}
