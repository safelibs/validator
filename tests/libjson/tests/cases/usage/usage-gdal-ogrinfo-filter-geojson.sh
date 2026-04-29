#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-filter-geojson
# @title: GDAL filters GeoJSON
# @description: Runs ogrinfo with an attribute filter against a GeoJSON fixture and verifies the selected feature.
# @timeout: 180
# @tags: usage, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="ogrinfo-filter"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogrinfo "$geojson" -al -where 'value=2' | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'beta'
