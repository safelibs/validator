#!/usr/bin/env bash
# @testcase: usage-gdal-r16-ogrinfo-json-so-suppresses-features
# @title: GDAL ogrinfo -json -so summary-only omits feature payloads
# @description: Runs ogrinfo -json -so on a 3-feature GeoJSON and asserts the json-c emitted output contains the layer summary (featureCount field) but does NOT contain any inline Feature payload, confirming -so still suppresses features even when -features is not given.
# @timeout: 180
# @tags: usage, gdal, json, ogrinfo, summary
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"id":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"id":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogrinfo -json -so "$tmpdir/in.geojson" >"$tmpdir/info.json"
jq -e '. | (.. | objects | select(has("featureCount"))) | .featureCount == 3' "$tmpdir/info.json"
jq -e '[.. | objects | select(.type? == "Feature")] | length == 0' "$tmpdir/info.json"
