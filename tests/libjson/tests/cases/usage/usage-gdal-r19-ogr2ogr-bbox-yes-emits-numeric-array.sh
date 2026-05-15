#!/usr/bin/env bash
# @testcase: usage-gdal-r19-ogr2ogr-bbox-yes-emits-numeric-array
# @title: GDAL ogr2ogr -lco WRITE_BBOX=YES emits a 4-number FeatureCollection bbox
# @description: Converts a multi-point GeoJSON with -lco WRITE_BBOX=YES and asserts the top-level bbox emitted via json-c is a 4-element array of numbers spanning the input extent, pinning the bbox layer-creation option shape.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, geojson, bbox, r19
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

ogr2ogr -f GeoJSON -lco WRITE_BBOX=YES "$tmpdir/out.geojson" "$tmpdir/in.geojson"
validator_require_file "$tmpdir/out.geojson"

jq -e '.bbox | type == "array" and length == 4 and all(.[]; type == "number")' "$tmpdir/out.geojson" >/dev/null
jq -e '.bbox == [0,0,10,5]' "$tmpdir/out.geojson" >/dev/null
