#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-gpkg-renamed-layer
# @title: gdal ogr2ogr GPKG renamed layer
# @description: Writes GeoJSON to a renamed GeoPackage layer with ogr2ogr and verifies the stored layer name through ogrinfo.
# @timeout: 180
# @tags: usage, gdal, conversion
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-gpkg-renamed-layer"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GPKG "$tmpdir/out.gpkg" "$geojson" -nln renamed_points_gpkg
ogrinfo "$tmpdir/out.gpkg" renamed_points_gpkg -so >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Layer name: renamed_points_gpkg'
