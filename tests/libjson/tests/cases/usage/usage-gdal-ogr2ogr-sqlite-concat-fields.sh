#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-sqlite-concat-fields
# @title: GDAL ogr2ogr SQLite concat fields
# @description: Uses the SQLite dialect to concatenate two attributes into a derived field and verifies the joined values appear in the GeoJSON output.
# @timeout: 180
# @tags: usage, gdal, sql, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-sqlite-concat-fields"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/concat.geojson" "$geojson" -dialect SQLITE -sql "SELECT name || '-' || \"group\" AS label FROM points ORDER BY name"
jq -e '.features[0].properties.label == "alpha-a"' "$tmpdir/concat.geojson"
jq -e '.features[1].properties.label == "beta-b"' "$tmpdir/concat.geojson"
