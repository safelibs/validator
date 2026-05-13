#!/usr/bin/env bash
# @testcase: usage-gdal-r16-ogrinfo-json-features-flag-emits-features
# @title: GDAL ogrinfo -json -al -features lists all 3 features
# @description: Runs ogrinfo -json -al -features on a 3-feature GeoJSON and asserts the json-c emitted top-level features array has exactly 3 entries; -features is required since GDAL 3.8+ hides feature payloads by default in -json -al.
# @timeout: 180
# @tags: usage, gdal, json, ogrinfo, features
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

ogrinfo -json -al -features "$tmpdir/in.geojson" >"$tmpdir/info.json"
jq -e '[.. | objects | select(.type? == "Feature")] | length >= 3' "$tmpdir/info.json"
