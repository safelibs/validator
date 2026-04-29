#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-spatial-filter
# @title: GDAL ogr2ogr spatial filter
# @description: Applies a spatial filter during GeoJSON export with ogr2ogr and verifies the reduced feature set.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-spatial-filter"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/spatial.geojson" "$geojson" -spat 0 0 4 5
jq -e '.features | length == 2' "$tmpdir/spatial.geojson"
