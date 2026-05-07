#!/usr/bin/env bash
# @testcase: usage-gdal-r12-ogrinfo-json-geometry-coordinates-point
# @title: GDAL ogrinfo -json -al emits Point geometry coordinates matching input
# @description: Writes a single-feature GeoJSON Point at coordinates [3.5, 4.5] and runs ogrinfo -json -al, verifying the json-c emitted .layers[0].features[0].geometry.type is "Point" and .coordinates equals [3.5, 4.5].
# @timeout: 180
# @tags: usage, gdal, json, geometry
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/p.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{},"geometry":{"type":"Point","coordinates":[3.5,4.5]}}
]}
JSON

ogrinfo -json -al "$tmpdir/p.geojson" >"$tmpdir/out.json"
jq -e '
  (.layers[0].features[0].geometry.type == "Point")
  and (.layers[0].features[0].geometry.coordinates == [3.5, 4.5])
' "$tmpdir/out.json"
