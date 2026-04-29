#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-sql-double-value
# @title: gdal ogr2ogr SQL double value
# @description: Runs an ogr2ogr SQLite SQL projection that doubles a numeric field and verifies the derived values in GeoJSON output.
# @timeout: 180
# @tags: usage, gdal, sql
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-sql-double-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/double.geojson" "$geojson" -dialect SQLITE -sql 'SELECT name, value * 2 AS doubled FROM points ORDER BY value'
jq -e '.features[0].properties.doubled == 2 and .features[2].properties.doubled == 6' "$tmpdir/double.geojson"
