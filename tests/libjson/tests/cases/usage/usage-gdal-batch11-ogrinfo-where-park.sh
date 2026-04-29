#!/usr/bin/env bash
# @testcase: usage-gdal-batch11-ogrinfo-where-park
# @title: GDAL ogrinfo park filter
# @description: Applies an ogrinfo attribute filter to a GeoJSON layer.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-batch11-ogrinfo-where-park"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogrinfo -ro "$tmpdir/places.geojson" -where "kind = 'park'" places >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
validator_assert_contains "$tmpdir/out" 'gamma'
