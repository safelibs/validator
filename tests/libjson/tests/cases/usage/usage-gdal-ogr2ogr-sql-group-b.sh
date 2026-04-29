#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-sql-group-b
# @title: GDAL ogr2ogr SQL subset
# @description: Runs an SQL query over GeoJSON data with ogr2ogr and verifies the subset output.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-sql-group-b"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/group-b.geojson" "$geojson" -sql "SELECT name, value FROM points WHERE group = 'b'"
jq -e '(.features | length == 2) and (.features[0].properties.name != null)' "$tmpdir/group-b.geojson"
