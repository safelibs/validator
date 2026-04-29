#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-reproject-geojson
# @title: GDAL reprojects GeoJSON
# @description: Runs ogr2ogr to reproject GeoJSON coordinates and verifies the resulting FeatureCollection.
# @timeout: 180
# @tags: usage, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload="ogr2ogr-reproject"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/reprojected.geojson" "$geojson" -s_srs EPSG:4326 -t_srs EPSG:3857
jq -e '
  .type == "FeatureCollection"
  and (.features | length) > 0
  and any(.features[]; (.geometry.coordinates | length) > 0)
' "$tmpdir/reprojected.geojson"
