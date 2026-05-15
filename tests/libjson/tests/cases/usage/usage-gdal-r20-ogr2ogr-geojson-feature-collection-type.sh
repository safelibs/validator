#!/usr/bin/env bash
# @testcase: usage-gdal-r20-ogr2ogr-geojson-feature-collection-type
# @title: GDAL ogr2ogr CSV-to-GeoJSON output has top-level "type":"FeatureCollection"
# @description: Converts a small CSV with WKT points to GeoJSON via ogr2ogr -f GeoJSON, then asserts the root .type field of the json-c-emitted output is exactly the string "FeatureCollection", pinning the canonical GeoJSON top-level container shape.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, geojson, type, r20
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,WKT
1,"POINT(0 0)"
2,"POINT(1 1)"
CSV
cat >"$tmpdir/in.csvt" <<'CSVT'
"Integer","String"
CSVT

ogr2ogr -f GeoJSON -a_srs EPSG:4326 "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '.type == "FeatureCollection"' "$tmpdir/out.geojson" >/dev/null
