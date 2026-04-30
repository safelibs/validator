#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-multipolygon-type
# @title: GDAL ogrinfo JSON multipolygon type
# @description: Reads a polygon GeoJSON layer with ogrinfo -json -al and verifies the geometry type metadata reports the Polygon family.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-json-multipolygon-type"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/poly.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"square"},"geometry":{"type":"Polygon","coordinates":[[[0,0],[2,0],[2,2],[0,2],[0,0]]]}}]}
JSON

ogrinfo -json -al -so "$geojson" >"$tmpdir/out.json"
jq -e '.layers[0].geometryFields[0].type | test("Polygon")' "$tmpdir/out.json"
jq -e '.layers[0].featureCount == 1' "$tmpdir/out.json"
