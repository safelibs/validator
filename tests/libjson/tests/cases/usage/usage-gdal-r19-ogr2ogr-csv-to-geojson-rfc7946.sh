#!/usr/bin/env bash
# @testcase: usage-gdal-r19-ogr2ogr-csv-to-geojson-rfc7946
# @title: GDAL ogr2ogr -lco RFC7946=YES emits a GeoJSON with WGS84 coordinates only
# @description: Converts a CSV with WKT points in EPSG:4326 to RFC 7946 GeoJSON via ogr2ogr -lco RFC7946=YES and asserts the json-c-emitted geometry coordinates have exactly two numbers, pinning the strict RFC7946 coordinate-shape contract.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, geojson, rfc7946, r19
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,WKT
1,"POINT(1.5 2.5)"
2,"POINT(3.5 4.5)"
CSV

cat >"$tmpdir/in.csvt" <<'CSVT'
"Integer","String"
CSVT

cat >"$tmpdir/in.prj" <<'PRJ'
GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433],AUTHORITY["EPSG","4326"]]
PRJ

ogr2ogr -f GeoJSON -a_srs EPSG:4326 -lco RFC7946=YES "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features | length == 2' "$tmpdir/out.geojson" >/dev/null
jq -e '[.features[].geometry.coordinates | length] | all(. == 2)' "$tmpdir/out.geojson" >/dev/null
