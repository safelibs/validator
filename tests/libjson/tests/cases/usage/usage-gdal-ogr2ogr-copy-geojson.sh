#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-copy-geojson
# @title: GDAL copies GeoJSON
# @description: Runs ogr2ogr to copy a GeoJSON fixture and verifies the copied feature data.
# @timeout: 180
# @tags: usage, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="ogr2ogr-copy"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/copy.geojson" "$geojson"
validator_assert_contains "$tmpdir/copy.geojson" 'beta'
