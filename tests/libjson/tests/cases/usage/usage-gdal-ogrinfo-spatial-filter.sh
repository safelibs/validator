#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-spatial-filter
# @title: GDAL spatial filter over GeoJSON
# @description: Runs ogrinfo with a spatial filter against GeoJSON and verifies the matching feature.
# @timeout: 180
# @tags: usage, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="ogrinfo-spatial-filter"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogrinfo "$geojson" -al -spat 0 0 2 3 | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'alpha'
