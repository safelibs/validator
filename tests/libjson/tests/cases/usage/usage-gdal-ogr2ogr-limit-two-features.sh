#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-limit-two-features
# @title: gdal ogr2ogr limit two features
# @description: Caps GeoJSON output with ogr2ogr -limit 2 and verifies the resulting feature collection contains exactly two features.
# @timeout: 180
# @tags: usage, gdal, geojson
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-limit-two-features"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/limit.geojson" "$geojson" -limit 2
jq -e '(.features | length) == 2' "$tmpdir/limit.geojson"
