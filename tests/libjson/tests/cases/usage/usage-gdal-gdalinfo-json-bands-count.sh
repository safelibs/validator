#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-bands-count
# @title: GDAL gdalinfo JSON bands count
# @description: Emits raster JSON metadata from gdalinfo and verifies at least one raster band is described.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-json-bands-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
gdalinfo -json "$raster" >"$tmpdir/out.json"
jq -e '.bands | length > 0' "$tmpdir/out.json"
