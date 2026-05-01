#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-makevalid-sql
# @title: GDAL ogr2ogr SQLite envelope SQL
# @description: Computes axis-aligned envelopes for GeoJSON points via an ogr2ogr -dialect SQLite -sql query using ST_Envelope and verifies the rewritten layer holds Polygon geometries with the original feature count preserved.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-makevalid-sql"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha"},"geometry":{"type":"Point","coordinates":[10,10]}},{"type":"Feature","properties":{"name":"beta"},"geometry":{"type":"Point","coordinates":[20,20]}},{"type":"Feature","properties":{"name":"gamma"},"geometry":{"type":"Point","coordinates":[30,30]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/envelopes.geojson" "$geojson" \
  -dialect SQLite -sql "SELECT name, ST_Envelope(ST_Buffer(geometry, 0.5)) AS geometry FROM points"

jq -e '
  .type == "FeatureCollection"
  and (.features | length) == 3
  and ([.features[].geometry.type] | all(. == "Polygon"))
  and ([.features[].properties.name] | sort == ["alpha","beta","gamma"])
' "$tmpdir/envelopes.geojson"
