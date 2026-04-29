#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-gpkg-geojson
# @title: GDAL converts GeoJSON to GeoPackage
# @description: Runs ogr2ogr to convert GeoJSON into GeoPackage and verifies the resulting layer metadata.
# @timeout: 180
# @tags: usage, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="ogr2ogr-gpkg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogr2ogr -f GPKG "$tmpdir/out.gpkg" "$geojson"
ogrinfo "$tmpdir/out.gpkg" -al -so | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Feature Count: 2'
