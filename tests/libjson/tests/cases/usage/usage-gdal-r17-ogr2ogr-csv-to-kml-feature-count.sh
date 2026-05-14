#!/usr/bin/env bash
# @testcase: usage-gdal-r17-ogr2ogr-csv-to-kml-feature-count
# @title: GDAL ogr2ogr CSV to KML preserves feature count of 3
# @description: Converts a 3-row WKT-bearing CSV to KML via ogr2ogr and asserts the resulting KML contains 3 Placemark elements, pinning Ubuntu 24.04 GDAL's CSV-to-KML feature parity.
# @timeout: 120
# @tags: usage, gdal, csv, kml
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,name,WKT
1,alpha,"POINT(0 0)"
2,beta,"POINT(1 1)"
3,gamma,"POINT(2 2)"
CSV
cat >"$tmpdir/in.csvt" <<'CSVT'
Integer,String,WKT
CSVT

ogr2ogr -f KML "$tmpdir/out.kml" "$tmpdir/in.csv"

validator_require_file "$tmpdir/out.kml"
count=$(grep -c '<Placemark>' "$tmpdir/out.kml")
[[ "$count" -eq 3 ]] || { printf 'expected 3 placemarks, got %s\n' "$count" >&2; exit 1; }
