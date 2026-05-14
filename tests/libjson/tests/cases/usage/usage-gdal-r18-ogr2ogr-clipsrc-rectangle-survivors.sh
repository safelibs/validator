#!/usr/bin/env bash
# @testcase: usage-gdal-r18-ogr2ogr-clipsrc-rectangle-survivors
# @title: GDAL ogr2ogr -clipsrc rectangle leaves only the inside point in the GeoJSON output
# @description: Runs ogr2ogr -clipsrc with a rectangle covering [-0.5,-0.5,0.5,0.5] over a 2-point CSV and asserts only the point at (0,0) survives in the emitted GeoJSON, locking the clipsrc filtering against the json-c writer.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, clipsrc, r18
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,WKT
1,"POINT(0 0)"
2,"POINT(10 10)"
CSV

ogr2ogr -f GeoJSON -clipsrc -0.5 -0.5 0.5 0.5 "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features | length == 1' "$tmpdir/out.geojson" >/dev/null
jq -e '.features[0].geometry.coordinates == [0,0]' "$tmpdir/out.geojson" >/dev/null
