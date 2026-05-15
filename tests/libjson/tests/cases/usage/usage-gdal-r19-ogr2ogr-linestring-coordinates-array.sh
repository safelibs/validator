#!/usr/bin/env bash
# @testcase: usage-gdal-r19-ogr2ogr-linestring-coordinates-array
# @title: GDAL ogr2ogr writes LineString geometries as an array of 2-element coordinate arrays
# @description: Converts a 3-vertex LineString GeoJSON through ogr2ogr to GeoJSON and asserts the json-c-emitted geometry.coordinates is an array of three 2-element numeric arrays, pinning the LineString output shape.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, geojson, linestring, r19
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"LineString","coordinates":[[0,0],[1,2],[3,4]]}}
]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/out.geojson" "$tmpdir/in.geojson"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features[0].geometry.type == "LineString"' "$tmpdir/out.geojson" >/dev/null
jq -e '.features[0].geometry.coordinates | length == 3 and all(.[]; type == "array" and length == 2 and all(.[]; type == "number"))' "$tmpdir/out.geojson" >/dev/null
