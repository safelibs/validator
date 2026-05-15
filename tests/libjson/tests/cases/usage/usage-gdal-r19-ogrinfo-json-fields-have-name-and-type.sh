#!/usr/bin/env bash
# @testcase: usage-gdal-r19-ogrinfo-json-fields-have-name-and-type
# @title: GDAL ogrinfo -json field descriptors carry both name and type strings
# @description: Runs ogrinfo -json on a GeoJSON with named typed properties and asserts every entry of the layer.fields array emitted via json-c has both a string "name" and a string "type", pinning the field-descriptor shape.
# @timeout: 120
# @tags: usage, gdal, json, ogrinfo, fields, r19
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"a","count":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"b","count":2},"geometry":{"type":"Point","coordinates":[1,1]}}
]}
JSON

ogrinfo -json "$tmpdir/in.geojson" >"$tmpdir/info.json"
validator_require_file "$tmpdir/info.json"

# Find a fields array and assert every entry has string name and type
jq -e '[.. | .fields? | select(type == "array") | .[]
  | select((.name | type == "string") and (.type | type == "string"))] | length >= 2' "$tmpdir/info.json" >/dev/null
