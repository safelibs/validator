#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-feature-coords
# @title: gdal ogrinfo JSON feature coords
# @description: Reads GeoJSON layer features with ogrinfo -json -al and verifies the second feature reports the expected point coordinates.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-json-feature-coords"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -json -al -features "$geojson" >"$tmpdir/out.json"
jq -e '.layers[0].features[1].geometry.coordinates == [3, 4]' "$tmpdir/out.json"
