#!/usr/bin/env bash
# @testcase: usage-gdal-r20-ogrinfo-json-layers-array-name-string
# @title: GDAL ogrinfo -json -al output exposes a layers-like array whose name is a string
# @description: Runs ogrinfo -json -al on a GeoJSON FeatureCollection and asserts that searching for any object with a string "name" field via jq finds at least one entry, pinning that json-c emits the layer descriptor's "name" as a JSON string in the ogrinfo -json -al payload.
# @timeout: 120
# @tags: usage, gdal, ogrinfo, json, layers, name, r20
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
  {"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}}
]}
JSON

ogrinfo -json -al "$tmpdir/in.geojson" >"$tmpdir/info.json"
validator_require_file "$tmpdir/info.json"

jq -e '[.. | objects | .name? // empty | select(type == "string")] | length >= 1' "$tmpdir/info.json" >/dev/null
