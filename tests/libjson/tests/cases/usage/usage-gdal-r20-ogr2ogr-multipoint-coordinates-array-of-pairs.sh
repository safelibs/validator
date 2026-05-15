#!/usr/bin/env bash
# @testcase: usage-gdal-r20-ogr2ogr-multipoint-coordinates-array-of-pairs
# @title: GDAL ogr2ogr CSV-WKT-multipoint to GeoJSON emits MultiPoint with array-of-pairs
# @description: Converts a CSV containing a WKT MULTIPOINT to GeoJSON via ogr2ogr and asserts the json-c-emitted feature has .geometry.type == "MultiPoint" and that every coordinate entry is an array of length 2 (x,y), pinning the MultiPoint serialization invariants.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, geojson, multipoint, r20
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,WKT
1,"MULTIPOINT((0 0),(1 1),(2 2))"
CSV
cat >"$tmpdir/in.csvt" <<'CSVT'
"Integer","String"
CSVT

ogr2ogr -f GeoJSON -a_srs EPSG:4326 "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features[0].geometry.type == "MultiPoint"' "$tmpdir/out.geojson" >/dev/null
jq -e '[.features[0].geometry.coordinates[] | length] | all(. == 2)' "$tmpdir/out.geojson" >/dev/null
jq -e '.features[0].geometry.coordinates | length == 3' "$tmpdir/out.geojson" >/dev/null
