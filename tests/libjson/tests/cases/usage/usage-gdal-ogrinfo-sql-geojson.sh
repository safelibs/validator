#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-sql-geojson
# @title: GDAL SQL over GeoJSON
# @description: Runs ogrinfo SQL against a GeoJSON fixture and verifies the projected feature value.
# @timeout: 180
# @tags: usage, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="ogrinfo-sql"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogrinfo "$geojson" -sql 'SELECT name FROM points WHERE value = 1' | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
