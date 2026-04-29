#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-append-gpkg
# @title: GDAL ogr2ogr append GPKG
# @description: Appends a second copy of the GeoJSON dataset into a GeoPackage through ogr2ogr and verifies the expanded feature count.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-append-gpkg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GPKG "$tmpdir/out.gpkg" "$geojson"
ogr2ogr -append -f GPKG "$tmpdir/out.gpkg" "$geojson"
ogrinfo "$tmpdir/out.gpkg" -al -so | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Feature Count: 6'
