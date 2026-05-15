#!/usr/bin/env bash
# @testcase: usage-gdal-r20-ogr2ogr-select-projects-single-column
# @title: GDAL ogr2ogr -select name on a multi-column CSV keeps only "name" in GeoJSON
# @description: Converts a CSV with two scalar columns (name, value) to GeoJSON via ogr2ogr -select name, then asserts every feature's .properties object has exactly one key "name" and no "value" key in the json-c-emitted output, pinning column projection.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, select, projection, r20
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
WKT,name,value
"POINT(0 0)",alpha,1
"POINT(1 1)",beta,2
CSV
cat >"$tmpdir/in.csvt" <<'CSVT'
"String","String","Integer"
CSVT

ogr2ogr -f GeoJSON -a_srs EPSG:4326 -select name "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '[.features[].properties | keys] | all(. == ["name"])' "$tmpdir/out.geojson" >/dev/null
