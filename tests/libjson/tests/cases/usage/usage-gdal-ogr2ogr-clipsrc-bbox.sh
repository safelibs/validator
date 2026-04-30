#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-clipsrc-bbox
# @title: GDAL ogr2ogr clipsrc bbox
# @description: Clips a GeoJSON feature collection to a bounding box with ogr2ogr -clipsrc and verifies only points inside the box survive.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-clipsrc-bbox"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/clipped.geojson" "$geojson" -clipsrc 0 0 4 5
jq -e '(.features | length) == 2' "$tmpdir/clipped.geojson"
jq -e '[.features[].properties.name] == ["alpha","beta"]' "$tmpdir/clipped.geojson"
