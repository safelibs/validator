#!/usr/bin/env bash
# @testcase: usage-gdal-r17-ogrinfo-json-geometry-type-point
# @title: GDAL ogrinfo -json reports Point geometry type for a point layer
# @description: Runs ogrinfo -json on a point-only GeoJSON and asserts the json-c output exposes a "geometryFields" entry whose type is "Point", pinning the geometry-type discovery contract.
# @timeout: 120
# @tags: usage, gdal, json, ogrinfo, geometry
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

ogrinfo -json "$tmpdir/in.geojson" >"$tmpdir/info.json"
validator_require_file "$tmpdir/info.json"

jq -e '[.. | objects | select(.type? == "Point" and (has("name")))] | length >= 1' "$tmpdir/info.json"
