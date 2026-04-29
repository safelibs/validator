#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-sql-count
# @title: GDAL ogrinfo SQL count
# @description: Runs an SQL aggregate over GeoJSON data and verifies the count result.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-sql-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo "$geojson" -sql "SELECT COUNT(*) AS total FROM points WHERE group = 'b'" | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'total (Integer) = 2'
