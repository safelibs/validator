#!/usr/bin/env bash
# @testcase: usage-gdal-r18-ogrinfo-json-feature-count-three
# @title: GDAL ogrinfo -json -features emits featureCount equal to 3 on a 3-feature input
# @description: Runs ogrinfo -json -features on a GeoJSON with three points and asserts at least one layer reports a featureCount of 3, locking the json-c-emitted feature accounting field on Ubuntu 24.04 gdal.
# @timeout: 120
# @tags: usage, gdal, json, ogrinfo, count, r18
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

ogrinfo -json -features "$tmpdir/in.geojson" >"$tmpdir/info.json"
validator_require_file "$tmpdir/info.json"

jq -e '[.. | objects | select(.featureCount? != null) | .featureCount] | any(. == 3)' "$tmpdir/info.json" >/dev/null
