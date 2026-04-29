#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-field-type-string-integer
# @title: gdal ogr2ogr field type string integer
# @description: Converts integer fields to strings with ogr2ogr and verifies the resulting GeoJSON property type is string.
# @timeout: 180
# @tags: usage, gdal, conversion
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-field-type-string-integer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/string.geojson" "$geojson" -fieldTypeToString Integer
jq -e '.features[0].properties.value == "1"' "$tmpdir/string.geojson"
