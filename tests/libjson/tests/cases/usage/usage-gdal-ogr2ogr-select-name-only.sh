#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-select-name-only
# @title: gdal ogr2ogr select name only
# @description: Restricts output fields with ogr2ogr -select name and verifies the resulting GeoJSON properties contain name but drop value.
# @timeout: 180
# @tags: usage, gdal, geojson
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-select-name-only"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/named.geojson" "$geojson" -select name
jq -e '.features[0].properties | has("name") and (has("value") | not)' "$tmpdir/named.geojson"
