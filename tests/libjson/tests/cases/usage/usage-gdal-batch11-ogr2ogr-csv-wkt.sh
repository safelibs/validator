#!/usr/bin/env bash
# @testcase: usage-gdal-batch11-ogr2ogr-csv-wkt
# @title: GDAL ogr2ogr CSV WKT
# @description: Converts GeoJSON to CSV with WKT geometry output.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-batch11-ogr2ogr-csv-wkt"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f CSV "$tmpdir/csv" "$tmpdir/places.geojson" -lco GEOMETRY=AS_WKT
validator_assert_contains "$tmpdir/csv/places.csv" 'POINT'
validator_assert_contains "$tmpdir/csv/places.csv" 'alpha'
