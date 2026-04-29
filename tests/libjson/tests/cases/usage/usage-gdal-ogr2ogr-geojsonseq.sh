#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-geojsonseq
# @title: GDAL GeoJSONSeq conversion
# @description: Converts GeoJSON to GeoJSONSeq and verifies serialized feature names.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-geojsonseq"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSONSeq "$tmpdir/out.geojsons" "$geojson"
validator_assert_contains "$tmpdir/out.geojsons" 'alpha'
validator_assert_contains "$tmpdir/out.geojsons" 'gamma'
