#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-checksum
# @title: GDAL gdalinfo JSON checksum
# @description: Runs gdalinfo JSON output with checksum metadata on the bundled GDAL icon.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-json-checksum"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
gdalinfo -json -checksum "$raster" >"$tmpdir/out.json"
jq -e '.driverShortName == "PNG" and (.bands[0].checksum | type == "number")' "$tmpdir/out.json"
