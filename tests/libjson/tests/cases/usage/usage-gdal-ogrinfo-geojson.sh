#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-geojson
# @title: GDAL reads GeoJSON
# @description: Runs ogrinfo against a GeoJSON fixture to exercise json-c parsing through GDAL.
# @timeout: 180
# @tags: usage, json, cli
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="ogrinfo-summary"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogrinfo "$geojson" -al -so | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Feature Count: 2'
