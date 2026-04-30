#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-nln-renamed-gpkg
# @title: GDAL ogr2ogr -nln renamed GeoPackage layer
# @description: Copies a small GeoJSON FeatureCollection into a GeoPackage with ogr2ogr -nln renamed_pts and verifies that ogrinfo -json reports the renamed layer name and the original feature count on the produced GPKG.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-nln-renamed-gpkg"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GPKG "$tmpdir/out.gpkg" "$geojson" -nln renamed_pts >"$tmpdir/ogr2ogr.log" 2>&1
validator_require_file "$tmpdir/out.gpkg"

ogrinfo -json "$tmpdir/out.gpkg" >"$tmpdir/out.json"
jq -e '
  any(.layers[]?; .name == "renamed_pts" and .featureCount == 3)
' "$tmpdir/out.json"
