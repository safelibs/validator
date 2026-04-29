#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-rename-layer
# @title: GDAL ogr2ogr layer rename
# @description: Copies GeoJSON while assigning a new layer name and verifies ogrinfo output.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-rename-layer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/renamed.geojson" "$geojson" -nln renamed_points
ogrinfo "$tmpdir/renamed.geojson" -al -so | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'renamed_points'
