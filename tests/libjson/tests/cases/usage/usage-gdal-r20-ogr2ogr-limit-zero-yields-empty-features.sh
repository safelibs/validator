#!/usr/bin/env bash
# @testcase: usage-gdal-r20-ogr2ogr-limit-zero-yields-empty-features
# @title: GDAL ogr2ogr -limit 0 produces a GeoJSON with an empty features array
# @description: Converts a 3-row CSV with WKT points to GeoJSON via ogr2ogr -limit 0 and asserts the json-c-emitted output's .features array has length 0 while .type remains "FeatureCollection", pinning the zero-limit behavior.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, limit, geojson, r20
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,WKT
1,"POINT(0 0)"
2,"POINT(1 1)"
3,"POINT(2 2)"
CSV
cat >"$tmpdir/in.csvt" <<'CSVT'
"Integer","String"
CSVT

ogr2ogr -f GeoJSON -a_srs EPSG:4326 -limit 0 "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '.type == "FeatureCollection"' "$tmpdir/out.geojson" >/dev/null
jq -e '.features | length == 0' "$tmpdir/out.geojson" >/dev/null
