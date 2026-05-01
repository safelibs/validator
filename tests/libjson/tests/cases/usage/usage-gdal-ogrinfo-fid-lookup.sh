#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-fid-lookup
# @title: GDAL ogrinfo -fid lookup
# @description: Looks up a single feature in a GeoJSON layer with ogrinfo -fid 1 -json and verifies the returned feature has fid 1 and the expected name property.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-fid-lookup"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -json -fid 1 "$geojson" points >"$tmpdir/out.json"
jq -e '
  .layers[0].features
  | length == 1
  and .[0].properties.name == "beta"
' "$tmpdir/out.json"
