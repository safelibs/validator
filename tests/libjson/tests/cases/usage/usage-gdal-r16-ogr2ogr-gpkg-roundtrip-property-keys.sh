#!/usr/bin/env bash
# @testcase: usage-gdal-r16-ogr2ogr-gpkg-roundtrip-property-keys
# @title: GDAL ogr2ogr GeoJSON to GPKG and back preserves property keys
# @description: Converts a 3-feature GeoJSON to GPKG with ogr2ogr, then back to GeoJSON, and asserts the property keys "name" and "kind" survive the round trip via jq -e on the json-c emitted FeatureCollection.
# @timeout: 180
# @tags: usage, gdal, json, gpkg, roundtrip
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park"},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road"},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park"},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f GPKG "$tmpdir/out.gpkg" "$tmpdir/in.geojson"
ogr2ogr -f GeoJSON "$tmpdir/back.geojson" "$tmpdir/out.gpkg"

jq -e '.features[0].properties | has("name") and has("kind")' "$tmpdir/back.geojson"
jq -e '[.features[].properties.name] | sort == ["alpha","beta","gamma"]' "$tmpdir/back.geojson"
