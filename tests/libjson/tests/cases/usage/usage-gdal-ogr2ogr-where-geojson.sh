#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-where-geojson
# @title: GDAL filters GeoJSON with ogr2ogr
# @description: Runs ogr2ogr with an attribute where clause and verifies only the matching GeoJSON feature is written.
# @timeout: 180
# @tags: usage, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="ogr2ogr-where"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/filtered.geojson" "$geojson" -where 'value=2'
validator_assert_contains "$tmpdir/filtered.geojson" 'beta'
if grep -Fq 'alpha' "$tmpdir/filtered.geojson"; then
    printf 'filtered GeoJSON unexpectedly retained alpha\n' >&2
    sed -n '1,120p' "$tmpdir/filtered.geojson" >&2
    exit 1
fi
