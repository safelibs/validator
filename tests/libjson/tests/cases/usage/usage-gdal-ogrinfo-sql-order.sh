#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-sql-order
# @title: GDAL ogrinfo SQL order
# @description: Queries GeoJSON data with ordered SQL through ogrinfo and verifies the highest-valued feature appears first.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-sql-order"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo "$geojson" -sql 'SELECT name FROM points ORDER BY value DESC' >"$tmpdir/out"
first=$(grep -F 'name (String)' "$tmpdir/out" | sed -n '1p')
validator_assert_contains "$tmpdir/out" 'gamma'
case "$first" in
  *gamma*) ;;
  *) printf 'unexpected first SQL row: %s\n' "$first" >&2; exit 1 ;;
esac
