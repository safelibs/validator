#!/usr/bin/env bash
# @testcase: usage-gdal-r12-ogrinfo-json-feature-properties-name-roundtrip
# @title: GDAL ogrinfo -json -al returns feature properties.name matching input
# @description: Writes a 2-feature GeoJSON FeatureCollection with distinct name properties and runs ogrinfo -json -al -features against it, verifying the json-c emitted .layers[0].features[].properties.name list equals the input names in order. (-features is required in GDAL 3.8+ to include feature payloads under the -json layer summary.)
# @timeout: 180
# @tags: usage, gdal, json, ogrinfo, features
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha"},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta"},"geometry":{"type":"Point","coordinates":[1,1]}}
]}
JSON

ogrinfo -json -al -features "$tmpdir/places.geojson" >"$tmpdir/out.json"
jq -e '
  ([.layers[0].features[].properties.name] == ["alpha", "beta"])
' "$tmpdir/out.json"
