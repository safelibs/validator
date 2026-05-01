#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-geojson-significant-figures
# @title: GDAL ogr2ogr GeoJSON SIGNIFICANT_FIGURES truncation
# @description: Rewrites a GeoJSON point with high-precision coordinates through ogr2ogr -lco SIGNIFICANT_FIGURES=4 and verifies the output coordinate digits are reduced to the requested precision while preserving the leading magnitude.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-geojson-significant-figures"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/in.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"n":1.123456789},"geometry":{"type":"Point","coordinates":[1.123456789,2.987654321]}}]}
JSON

ogr2ogr -f GeoJSON -lco SIGNIFICANT_FIGURES=4 "$tmpdir/out.geojson" "$geojson"
validator_require_file "$tmpdir/out.geojson"

jq -e '
  (.features | length) == 1
  and (.features[0].geometry.coordinates[0] == 1.123)
  and (.features[0].geometry.coordinates[1] == 2.988)
' "$tmpdir/out.geojson"
