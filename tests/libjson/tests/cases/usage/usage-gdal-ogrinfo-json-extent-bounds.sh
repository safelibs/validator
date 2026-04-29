#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-extent-bounds
# @title: gdal ogrinfo JSON extent bounds
# @description: Reads GeoJSON layer metadata with ogrinfo -json -al and verifies the geometry extent bounds match the input coordinates.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-json-extent-bounds"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -json -al "$geojson" >"$tmpdir/out.json"
jq -e '.layers[0].geometryFields[0].extent == [1, 2, 5, 6]' "$tmpdir/out.json"
