#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-raster
# @title: GDAL raster JSON metadata
# @description: Runs gdalinfo JSON output against a small raster fixture and verifies the reported driver metadata.
# @timeout: 180
# @tags: usage, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="gdalinfo-json-raster"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
gdalinfo -json "$raster" >"$tmpdir/out.json"
jq -e '.driverShortName == "PNG"' "$tmpdir/out.json"
