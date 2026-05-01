#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-buffer-sql
# @title: GDAL ogr2ogr SQL buffer geometry
# @description: Buffers a GeoJSON point layer through an ogr2ogr -dialect SQLite -sql query that calls ST_Buffer and verifies the output features carry Polygon geometry rather than Point.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-buffer-sql"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha"},"geometry":{"type":"Point","coordinates":[10,10]}},{"type":"Feature","properties":{"name":"beta"},"geometry":{"type":"Point","coordinates":[20,20]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/buffered.geojson" "$geojson" \
  -dialect SQLite -sql "SELECT name, ST_Buffer(geometry, 1.0) AS geometry FROM points"

jq -e '
  .type == "FeatureCollection"
  and (.features | length) == 2
  and ([.features[].geometry.type] | all(. == "Polygon"))
' "$tmpdir/buffered.geojson"
