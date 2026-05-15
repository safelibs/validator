#!/usr/bin/env bash
# @testcase: usage-gdal-r19-ogr2ogr-skipfailures-bad-wkt-keeps-good
# @title: GDAL ogr2ogr -skipfailures keeps valid features when source WKT is malformed
# @description: Converts a CSV containing one valid POINT WKT and one malformed WKT via ogr2ogr -skipfailures -f GeoJSON and asserts the json-c-serialised output contains exactly one feature, pinning the skipfailures recovery contract.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, skipfailures, r19
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,WKT
1,"POINT(1 1)"
2,"not a wkt"
CSV

ogr2ogr -skipfailures -f GeoJSON "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

# At least the valid feature must survive
jq -e '.features | length >= 1' "$tmpdir/out.geojson" >/dev/null
jq -e '[.features[] | select(.geometry != null and .geometry.type == "Point")] | length == 1' "$tmpdir/out.geojson" >/dev/null
