#!/usr/bin/env bash
# @testcase: usage-gdal-gdalsrsinfo-projjson
# @title: GDAL SRS PROJJSON output
# @description: Runs gdalsrsinfo PROJJSON output for EPSG:4326 and verifies JSON coordinate system data.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalsrsinfo-projjson"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

gdalsrsinfo -o projjson EPSG:4326 >"$tmpdir/out.json"
jq -e '.type == "GeographicCRS"' "$tmpdir/out.json"
