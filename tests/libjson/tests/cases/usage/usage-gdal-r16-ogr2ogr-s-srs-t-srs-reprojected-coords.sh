#!/usr/bin/env bash
# @testcase: usage-gdal-r16-ogr2ogr-s-srs-t-srs-reprojected-coords
# @title: GDAL ogr2ogr -s_srs EPSG:4326 -t_srs EPSG:3857 emits non-degree coordinates
# @description: Reprojects a 4326 GeoJSON point at (10, 50) to EPSG:3857 with ogr2ogr -s_srs/-t_srs and asserts the json-c emitted output's first coordinate has absolute value greater than 100000 (web-mercator metres), confirming reprojection happened.
# @timeout: 180
# @tags: usage, gdal, json, reproject
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[10,50]}}
]}
JSON

ogr2ogr -f GeoJSON -s_srs EPSG:4326 -t_srs EPSG:3857 "$tmpdir/out.geojson" "$tmpdir/in.geojson"
jq -e '(.features[0].geometry.coordinates[0] | fabs) > 100000' "$tmpdir/out.geojson"
