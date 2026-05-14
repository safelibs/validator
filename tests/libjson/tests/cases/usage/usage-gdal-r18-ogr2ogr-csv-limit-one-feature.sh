#!/usr/bin/env bash
# @testcase: usage-gdal-r18-ogr2ogr-csv-limit-one-feature
# @title: GDAL ogr2ogr -limit 1 emits a single feature into the output GeoJSON
# @description: Converts a 3-feature CSV with WKT to GeoJSON via ogr2ogr -limit 1 and asserts the emitted FeatureCollection has exactly one feature, locking the json-c-driven limit clause feature count.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, limit, r18
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

ogr2ogr -f GeoJSON -limit 1 "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features | length == 1' "$tmpdir/out.geojson" >/dev/null
