#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-esri-shapefile
# @title: GDAL ogr2ogr ESRI Shapefile output
# @description: Converts a GeoJSON FeatureCollection to an ESRI Shapefile with ogr2ogr and verifies that the full shapefile suite (.shp/.shx/.dbf) is produced and that ogrinfo reports the expected feature count.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-esri-shapefile"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f 'ESRI Shapefile' "$tmpdir/shp" "$tmpdir/places.geojson" >"$tmpdir/ogr.log" 2>&1
validator_require_file "$tmpdir/shp/places.shp"
validator_require_file "$tmpdir/shp/places.shx"
validator_require_file "$tmpdir/shp/places.dbf"

ogrinfo -al -so "$tmpdir/shp/places.shp" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Feature Count: 3'
