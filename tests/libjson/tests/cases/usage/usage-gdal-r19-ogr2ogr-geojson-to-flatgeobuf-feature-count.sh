#!/usr/bin/env bash
# @testcase: usage-gdal-r19-ogr2ogr-geojson-to-flatgeobuf-feature-count
# @title: GDAL ogr2ogr GeoJSON to FlatGeobuf preserves the feature count via ogrinfo -json
# @description: Converts a 4-feature GeoJSON to FlatGeobuf via ogr2ogr -f FlatGeobuf and reads the resulting layer with ogrinfo -json -so, asserting the json-c-emitted featureCount field equals 4.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, flatgeobuf, feature-count, r19
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"id":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"id":3},"geometry":{"type":"Point","coordinates":[2,2]}},
{"type":"Feature","properties":{"id":4},"geometry":{"type":"Point","coordinates":[3,3]}}
]}
JSON

ogr2ogr -f FlatGeobuf "$tmpdir/out.fgb" "$tmpdir/in.geojson"
validator_require_file "$tmpdir/out.fgb"

ogrinfo -json -so "$tmpdir/out.fgb" >"$tmpdir/info.json"
jq -e '[.. | objects | select(.featureCount? == 4)] | length >= 1' "$tmpdir/info.json" >/dev/null
