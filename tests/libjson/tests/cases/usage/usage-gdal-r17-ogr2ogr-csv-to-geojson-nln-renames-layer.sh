#!/usr/bin/env bash
# @testcase: usage-gdal-r17-ogr2ogr-csv-to-geojson-nln-renames-layer
# @title: GDAL ogr2ogr -nln renames the output layer name in GeoJSON
# @description: Converts a CSV with WKT to GeoJSON via ogr2ogr -nln renamed_layer and asserts the top-level "name" field in the emitted GeoJSON matches the requested layer name, exercising json-c output naming.
# @timeout: 120
# @tags: usage, gdal, csv, geojson, nln
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

ogr2ogr -f GeoJSON -nln renamed_layer "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '.name == "renamed_layer"' "$tmpdir/out.geojson"
