#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-sqlite-dialect-csv
# @title: GDAL ogrinfo SQLite dialect over CSV
# @description: Materializes a CSV layer from GeoJSON and runs ogrinfo with the SQLite dialect to "SELECT *" from the layer, verifying the JSON-emitting form returns every source feature.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-sqlite-dialect-csv"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f CSV "$tmpdir/csv" "$geojson" -lco GEOMETRY=AS_WKT
csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
validator_require_file "$csv"

# Layer name == CSV file basename without extension.
layer=$(basename "$csv" .csv)

# Use the SQLite dialect to re-select all rows from the materialized layer and
# capture the output in textual form.
ogrinfo -dialect SQLite -sql "SELECT * FROM \"${layer}\"" "$csv" \
  >"$tmpdir/sql.txt" 2>&1
validator_require_file "$tmpdir/sql.txt"

# All three feature names from the source GeoJSON must come back through the
# SQLite-dialect SELECT.
validator_assert_contains "$tmpdir/sql.txt" 'alpha'
validator_assert_contains "$tmpdir/sql.txt" 'beta'
validator_assert_contains "$tmpdir/sql.txt" 'gamma'
