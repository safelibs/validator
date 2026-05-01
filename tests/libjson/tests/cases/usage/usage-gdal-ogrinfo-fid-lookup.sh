#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-fid-lookup
# @title: GDAL ogrinfo -fid feature lookup
# @description: Looks up a single feature in a GeoJSON layer with ogrinfo -fid 1 and asserts the returned feature has FID 1 and a property name.
# @timeout: 180
# @tags: usage, gdal, geojson
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-fid-lookup"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -fid 1 "$geojson" points >"$tmpdir/out.txt"
validator_assert_contains "$tmpdir/out.txt" "OGRFeature(points):1"
validator_assert_contains "$tmpdir/out.txt" "POINT (3 4)"
validator_assert_contains "$tmpdir/out.txt" "name (String) = beta"
