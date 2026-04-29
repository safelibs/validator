#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-corner-coordinates
# @title: GDAL gdalinfo JSON corner coordinates
# @description: Exercises gdal gdalinfo json corner coordinates through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-json-corner-coordinates"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
gdalinfo -json "$raster" >"$tmpdir/out.json"
jq -e '(.cornerCoordinates.upperLeft | length) == 2 and (.cornerCoordinates.lowerRight | length) == 2' "$tmpdir/out.json"
