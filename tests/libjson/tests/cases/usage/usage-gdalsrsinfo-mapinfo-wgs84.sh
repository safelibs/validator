#!/usr/bin/env bash
# @testcase: usage-gdalsrsinfo-mapinfo-wgs84
# @title: gdalsrsinfo mapinfo WGS84
# @description: Emits a MapInfo coordinate system description with gdalsrsinfo and verifies the projection header text.
# @timeout: 180
# @tags: usage, gdal, srs
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdalsrsinfo-mapinfo-wgs84"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

gdalsrsinfo -o mapinfo EPSG:4326 >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Earth Projection'
