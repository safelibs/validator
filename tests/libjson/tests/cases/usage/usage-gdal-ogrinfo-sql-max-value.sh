#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-sql-max-value
# @title: GDAL ogrinfo SQL max value
# @description: Exercises gdal ogrinfo sql max value through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-sql-max-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo "$geojson" -sql 'SELECT MAX(value) AS max_value FROM points' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'max_value'
validator_assert_contains "$tmpdir/out" '3'
