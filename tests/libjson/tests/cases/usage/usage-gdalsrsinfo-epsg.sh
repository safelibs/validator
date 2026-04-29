#!/usr/bin/env bash
# @testcase: usage-gdalsrsinfo-epsg
# @title: GDAL gdalsrsinfo EPSG
# @description: Resolves a spatial reference through gdalsrsinfo and verifies the EPSG authority code is reported.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdalsrsinfo-epsg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

gdalsrsinfo -o epsg EPSG:4326 >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'EPSG:4326'
