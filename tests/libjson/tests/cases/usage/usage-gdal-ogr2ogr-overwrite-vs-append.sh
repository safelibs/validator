#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-overwrite-vs-append
# @title: GDAL ogr2ogr -overwrite vs -append
# @description: Materializes a GeoPackage from GeoJSON, then re-runs ogr2ogr with -overwrite and verifies the layer feature count is reset to the source size rather than doubled as it would be with -append.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-overwrite-vs-append"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/places.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f GPKG "$tmpdir/out.gpkg" "$geojson" >"$tmpdir/initial.log" 2>&1
ogrinfo -al -so "$tmpdir/out.gpkg" >"$tmpdir/initial.info"
validator_assert_contains "$tmpdir/initial.info" 'Feature Count: 3'

# -overwrite must replace the layer rather than appending, so the feature count
# stays at 3 (whereas -append would yield 6).
ogr2ogr -f GPKG -overwrite "$tmpdir/out.gpkg" "$geojson" >"$tmpdir/overwrite.log" 2>&1
ogrinfo -al -so "$tmpdir/out.gpkg" >"$tmpdir/overwrite.info"
validator_assert_contains "$tmpdir/overwrite.info" 'Feature Count: 3'
if grep -Fq 'Feature Count: 6' "$tmpdir/overwrite.info"; then
  printf '-overwrite unexpectedly produced an appended feature count\n' >&2
  exit 1
fi
