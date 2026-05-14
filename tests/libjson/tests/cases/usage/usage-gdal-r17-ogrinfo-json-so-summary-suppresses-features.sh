#!/usr/bin/env bash
# @testcase: usage-gdal-r17-ogrinfo-json-so-summary-suppresses-features
# @title: GDAL ogrinfo -json -so suppresses feature payloads while keeping layer metadata
# @description: Runs ogrinfo -json -so on a 3-feature GeoJSON and asserts the json-c output has no top-level features list while still emitting the layer entry, locking in the summary-only mode shape distinct from -features.
# @timeout: 120
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
validator_require_file "$tmpdir/info.json"

# In -so mode there must be no feature objects inline.
jq -e '[.. | objects | select(.type? == "Feature")] | length == 0' "$tmpdir/info.json"
# The layers list must still exist and be non-empty.
jq -e '.layers | type == "array" and length >= 1' "$tmpdir/info.json"
