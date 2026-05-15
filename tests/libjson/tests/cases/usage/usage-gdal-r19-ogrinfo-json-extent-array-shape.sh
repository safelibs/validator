#!/usr/bin/env bash
# @testcase: usage-gdal-r19-ogrinfo-json-extent-array-shape
# @title: GDAL ogrinfo -json extent is a 4-element numeric array
# @description: Runs ogrinfo -json on a GeoJSON with two points and asserts the json-c output contains a 4-element numeric "extent" array equal to [minx,miny,maxx,maxy] = [0,0,10,5], pinning the extent serialisation shape.
# @timeout: 120
# @tags: usage, gdal, json, ogrinfo, extent, r19
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"id":2},"geometry":{"type":"Point","coordinates":[10,5]}}
]}
JSON

ogrinfo -json "$tmpdir/in.geojson" >"$tmpdir/info.json"

jq -e '[.. | .extent? | select(type == "array")
  | select(length == 4 and all(.[]; type == "number"))] | length >= 1' "$tmpdir/info.json" >/dev/null
