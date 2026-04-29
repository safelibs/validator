#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-sql-sum-value
# @title: gdal ogrinfo SQL sum value
# @description: Runs an ogrinfo SQLite SQL query that sums feature values and verifies the aggregated total in the output.
# @timeout: 180
# @tags: usage, gdal, sql
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-sql-sum-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo "$geojson" -dialect SQLITE -sql 'SELECT SUM(value) AS total_value FROM points' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'total_value'
validator_assert_contains "$tmpdir/out" '6'
