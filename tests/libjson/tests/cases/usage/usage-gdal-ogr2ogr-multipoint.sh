#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-multipoint
# @title: GDAL ogr2ogr multipoint
# @description: Forces GeoJSON output geometry to MultiPoint with ogr2ogr and verifies the geometry type.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-multipoint"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/multipoint.geojson" "$geojson" -nlt MULTIPOINT
jq -e '.features[0].geometry.type == "MultiPoint"' "$tmpdir/multipoint.geojson"
