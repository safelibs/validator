#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-field-types
# @title: GDAL ogrinfo JSON field types
# @description: Runs ogrinfo -json -al -so against a GeoJSON layer and verifies the declared field types include both String and Integer entries.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-json-field-types"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogrinfo -json -al -so "$geojson" >"$tmpdir/out.json"
jq -e '[.layers[0].fields[].type] | index("String") != null' "$tmpdir/out.json"
jq -e '[.layers[0].fields[].type] | index("Integer") != null' "$tmpdir/out.json"
