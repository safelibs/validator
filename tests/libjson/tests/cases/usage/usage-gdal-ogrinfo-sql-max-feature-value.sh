#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-sql-max-feature-value
# @title: gdal ogrinfo SQL max feature value
# @description: Runs an ogrinfo SQLite SQL query that selects MAX(value) into an alias and verifies the largest feature value in the output.
# @timeout: 180
# @tags: usage, gdal, sql
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-sql-max-feature-value"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo "$geojson" -dialect SQLITE -sql 'SELECT MAX(value) AS max_feature FROM points' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'max_feature'
validator_assert_contains "$tmpdir/out" '3'
