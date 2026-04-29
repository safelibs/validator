#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-where-name
# @title: GDAL ogrinfo where filter
# @description: Filters GeoJSON features with ogrinfo where syntax and verifies only the matching feature remains.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-where-name"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo "$geojson" -where "name = 'alpha'" -al | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
if grep -Fq 'gamma' "$tmpdir/out"; then exit 1; fi
