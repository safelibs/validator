#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-coordinate-precision
# @title: GDAL ogr2ogr coordinate precision
# @description: Rewrites GeoJSON with rounded coordinate precision through ogr2ogr and verifies integral coordinates are emitted.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-coordinate-precision"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/rounded.geojson" "$geojson" -lco COORDINATE_PRECISION=0
jq -e 'all(.features[]; all(.geometry.coordinates[]; . == floor))' "$tmpdir/rounded.geojson"
