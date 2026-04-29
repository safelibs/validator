#!/usr/bin/env bash
# @testcase: usage-gdal-batch11-ogrinfo-feature-count
# @title: GDAL ogrinfo feature count
# @description: Reads a GeoJSON layer with ogrinfo and checks the feature count.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-batch11-ogrinfo-feature-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogrinfo -ro -al -so "$tmpdir/places.geojson" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Feature Count: 3'
