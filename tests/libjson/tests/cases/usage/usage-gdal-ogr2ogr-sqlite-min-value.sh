#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-sqlite-min-value
# @title: GDAL ogr2ogr SQLite MIN value
# @description: Runs an ogr2ogr SQLite dialect query that selects the minimum numeric attribute and verifies the aggregate value in the GeoJSON output.
# @timeout: 180
# @tags: usage, gdal, sql, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-sqlite-min-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/min.geojson" "$geojson" -dialect SQLITE -sql 'SELECT MIN(value) AS min_value FROM points'
jq -e '.features[0].properties.min_value == 1' "$tmpdir/min.geojson"
