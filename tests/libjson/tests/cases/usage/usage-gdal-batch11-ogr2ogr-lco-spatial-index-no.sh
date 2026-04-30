#!/usr/bin/env bash
# @testcase: usage-gdal-batch11-ogr2ogr-lco-spatial-index-no
# @title: GDAL ogr2ogr disable shapefile spatial index
# @description: Converts a GeoJSON FeatureCollection to ESRI Shapefile with -lco SPATIAL_INDEX=NO and verifies that the .qix spatial-index sidecar is not produced while the shapefile components are.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-batch11-ogr2ogr-lco-spatial-index-no"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

mkdir -p "$tmpdir/shp"
ogr2ogr -f "ESRI Shapefile" -lco SPATIAL_INDEX=NO \
  "$tmpdir/shp" "$tmpdir/places.geojson" >"$tmpdir/ogr2ogr.log" 2>&1

validator_require_file "$tmpdir/shp/places.shp"
validator_require_file "$tmpdir/shp/places.dbf"
validator_require_file "$tmpdir/shp/places.shx"

if [[ -e "$tmpdir/shp/places.qix" ]]; then
  printf 'unexpected .qix spatial index present despite SPATIAL_INDEX=NO\n' >&2
  ls -la "$tmpdir/shp" >&2
  exit 1
fi
