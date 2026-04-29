#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-sql-between-values
# @title: gdal ogrinfo SQL between values
# @description: Runs an ogrinfo SQLite SQL filter with a BETWEEN predicate and verifies both selected feature names in the output.
# @timeout: 180
# @tags: usage, gdal, sql
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-sql-between-values"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo "$geojson" -dialect SQLITE -sql 'SELECT name FROM points WHERE value BETWEEN 2 AND 3 ORDER BY value' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'beta'
validator_assert_contains "$tmpdir/out" 'gamma'
