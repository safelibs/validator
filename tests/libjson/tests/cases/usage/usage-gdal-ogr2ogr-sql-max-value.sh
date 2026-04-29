#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-sql-max-value
# @title: GDAL ogr2ogr SQL max value
# @description: Exercises gdal ogr2ogr sql max value through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-sql-max-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/max.geojson" "$geojson" -dialect SQLITE -sql 'SELECT MAX(value) AS max_value FROM points'
jq -e '.features[0].properties.max_value == 3' "$tmpdir/max.geojson"
