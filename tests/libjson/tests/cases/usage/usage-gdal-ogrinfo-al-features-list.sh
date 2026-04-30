#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-al-features-list
# @title: GDAL ogrinfo -al full feature list
# @description: Runs ogrinfo -al (without -so) on a GeoJSON FeatureCollection and verifies the textual output enumerates every feature record by checking the OGRFeature markers and per-feature property values for all three sample points.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-al-features-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -al "$geojson" >"$tmpdir/out.txt" 2>&1
validator_require_file "$tmpdir/out.txt"

# The unsummarised -al output prints one "OGRFeature" header per feature.
ogr_count=$(grep -c '^OGRFeature' "$tmpdir/out.txt")
[[ "$ogr_count" -eq 3 ]] || {
  printf 'expected 3 OGRFeature records, got %s\n' "$ogr_count" >&2
  sed -n '1,80p' "$tmpdir/out.txt" >&2
  exit 1
}

validator_assert_contains "$tmpdir/out.txt" 'alpha'
validator_assert_contains "$tmpdir/out.txt" 'beta'
validator_assert_contains "$tmpdir/out.txt" 'gamma'
validator_assert_contains "$tmpdir/out.txt" 'POINT'
