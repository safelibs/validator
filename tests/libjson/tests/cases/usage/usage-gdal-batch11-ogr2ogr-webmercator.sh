#!/usr/bin/env bash
# @testcase: usage-gdal-batch11-ogr2ogr-webmercator
# @title: GDAL ogr2ogr Web Mercator
# @description: Reprojects GeoJSON features to EPSG:3857 with ogr2ogr.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-batch11-ogr2ogr-webmercator"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/webm.geojson" "$tmpdir/places.geojson" -t_srs EPSG:3857
validator_assert_contains "$tmpdir/webm.geojson" 'FeatureCollection'
