#!/usr/bin/env bash
# @testcase: usage-gdal-r18-ogr2ogr-spat-clip-bbox-feature-count
# @title: GDAL ogr2ogr -spat clips features outside the bbox in the emitted GeoJSON
# @description: Converts a 3-point CSV to GeoJSON with ogr2ogr -spat 0 0 1 1 and asserts only two features survive — the points at (0,0) and (1,1) — locking the spatial filter feature count emitted via the json-c writer.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, spat, r18
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,WKT
1,"POINT(0 0)"
2,"POINT(1 1)"
3,"POINT(5 5)"
CSV

ogr2ogr -f GeoJSON -spat 0 0 1 1 "$tmpdir/out.geojson" "$tmpdir/in.csv"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features | length == 2' "$tmpdir/out.geojson" >/dev/null
