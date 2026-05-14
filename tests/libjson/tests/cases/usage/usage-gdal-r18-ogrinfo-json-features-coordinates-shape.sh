#!/usr/bin/env bash
# @testcase: usage-gdal-r18-ogrinfo-json-features-coordinates-shape
# @title: GDAL ogrinfo -json -features emits Point coordinates as a 2-number array
# @description: Runs ogrinfo -json -features on a single-Point GeoJSON and asserts the emitted feature geometry coordinates field is a 2-element numeric array, pinning the json-c output shape for Point geometries.
# @timeout: 120
# @tags: usage, gdal, json, ogrinfo, coordinates, r18
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[3.5,4.5]}}
]}
JSON

ogrinfo -json -features "$tmpdir/in.geojson" >"$tmpdir/info.json"
validator_require_file "$tmpdir/info.json"

jq -e '[.. | objects | select(.type? == "Point" and (.coordinates? | type == "array"))
  | .coordinates | select(length == 2 and (.[0] | type == "number") and (.[1] | type == "number"))]
  | length >= 1' "$tmpdir/info.json" >/dev/null
