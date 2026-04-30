#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-gpkg-multilayer-json
# @title: GDAL ogrinfo GPKG multilayer JSON
# @description: Builds a GeoPackage that holds two named layers via successive ogr2ogr -append invocations and verifies that ogrinfo -json -al -so reports both layers with their distinct feature counts.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-gpkg-multilayer-json"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/parks.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
  {"type":"Feature","properties":{"name":"alpha"},"geometry":{"type":"Point","coordinates":[1,2]}},
  {"type":"Feature","properties":{"name":"beta"},"geometry":{"type":"Point","coordinates":[3,4]}}
]}
JSON

cat >"$tmpdir/roads.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
  {"type":"Feature","properties":{"name":"main"},"geometry":{"type":"Point","coordinates":[5,6]}},
  {"type":"Feature","properties":{"name":"side"},"geometry":{"type":"Point","coordinates":[7,8]}},
  {"type":"Feature","properties":{"name":"alley"},"geometry":{"type":"Point","coordinates":[9,10]}}
]}
JSON

gpkg="$tmpdir/places.gpkg"
ogr2ogr -f GPKG "$gpkg" "$tmpdir/parks.geojson" -nln parks
ogr2ogr -update -append -f GPKG "$gpkg" "$tmpdir/roads.geojson" -nln roads

ogrinfo -json -al -so "$gpkg" >"$tmpdir/out.json"
jq -e '
  (.layers | length) == 2
  and ((.layers | map(.name) | sort) == ["parks","roads"])
  and ((.layers | map(select(.name == "parks") | .featureCount)[0]) == 2)
  and ((.layers | map(select(.name == "roads") | .featureCount)[0]) == 3)
' "$tmpdir/out.json"
