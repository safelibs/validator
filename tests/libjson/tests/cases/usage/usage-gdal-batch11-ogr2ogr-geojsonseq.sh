#!/usr/bin/env bash
# @testcase: usage-gdal-batch11-ogr2ogr-geojsonseq
# @title: GDAL ogr2ogr GeoJSONSeq
# @description: Converts GeoJSON features to GeoJSONSeq with ogr2ogr.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-batch11-ogr2ogr-geojsonseq"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f GeoJSONSeq "$tmpdir/out.geojsons" "$tmpdir/places.geojson"
validator_assert_contains "$tmpdir/out.geojsons" 'Feature'
