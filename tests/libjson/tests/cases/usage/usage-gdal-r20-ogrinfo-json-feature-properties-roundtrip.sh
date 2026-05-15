#!/usr/bin/env bash
# @testcase: usage-gdal-r20-ogrinfo-json-feature-properties-roundtrip
# @title: GDAL ogrinfo -json -features preserves integer property values
# @description: Reads a GeoJSON FeatureCollection with integer "count" properties via ogrinfo -json -features and asserts that searching for any feature with property count == 7 succeeds in the json-c-emitted payload, pinning numeric property round-trip through ogrinfo's feature dump.
# @timeout: 120
# @tags: usage, gdal, ogrinfo, json, features, properties, r20
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
  {"type":"Feature","properties":{"count":7},"geometry":{"type":"Point","coordinates":[0,0]}},
  {"type":"Feature","properties":{"count":9},"geometry":{"type":"Point","coordinates":[1,1]}}
]}
JSON

ogrinfo -json -features "$tmpdir/in.geojson" >"$tmpdir/info.json"
validator_require_file "$tmpdir/info.json"

jq -e '[.. | objects | select(.properties? != null) | .properties.count? | select(. == 7)] | length >= 1' "$tmpdir/info.json" >/dev/null
