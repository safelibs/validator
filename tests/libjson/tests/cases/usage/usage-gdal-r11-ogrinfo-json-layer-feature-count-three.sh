#!/usr/bin/env bash
# @testcase: usage-gdal-r11-ogrinfo-json-layer-feature-count-three
# @title: GDAL ogrinfo JSON layer featureCount equals input feature count
# @description: Writes a 3-feature GeoJSON FeatureCollection and runs ogrinfo -json against it, verifying the json-c emitted .layers[0].featureCount equals 3 and .layers[0].name matches the input file stem.
# @timeout: 180
# @tags: usage, gdal, json, ogrinfo
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha"},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta"},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma"},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogrinfo -json "$tmpdir/places.geojson" >"$tmpdir/out.json"
jq -e '
  (.layers | length >= 1)
  and (.layers[0].featureCount == 3)
  and (.layers[0].name == "places")
' "$tmpdir/out.json"
