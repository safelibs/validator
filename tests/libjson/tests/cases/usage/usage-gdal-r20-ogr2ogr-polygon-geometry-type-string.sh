#!/usr/bin/env bash
# @testcase: usage-gdal-r20-ogr2ogr-polygon-geometry-type-string
# @title: GDAL ogr2ogr CSV-WKT-polygon to GeoJSON emits feature geometry type "Polygon"
# @description: Converts a CSV containing a WKT POLYGON to GeoJSON via ogr2ogr and asserts every feature in the json-c-emitted output has .geometry.type == "Polygon", pinning the polygon geometry type-string serialization.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, geojson, polygon, r20
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,WKT
1,"POLYGON((0 0,1 0,1 1,0 1,0 0))"
CSV
cat >"$tmpdir/in.csvt" <<'CSVT'
"Integer","String"
CSVT

ogr2ogr -f GeoJSON -a_srs EPSG:4326 "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '[.features[].geometry.type] | all(. == "Polygon")' "$tmpdir/out.geojson" >/dev/null
