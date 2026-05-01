#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-geojson-id-field
# @title: GDAL ogr2ogr GeoJSON ID_FIELD promotion
# @description: Rewrites a small GeoJSON FeatureCollection through ogr2ogr with -lco ID_FIELD=n and verifies the json-c GeoJSON writer promotes the named integer property into a top-level Feature id, while removing it from properties.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-geojson-id-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/in.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"n":11,"name":"alpha"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"n":22,"name":"beta"},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogr2ogr -f GeoJSON -lco ID_FIELD=n "$tmpdir/out.geojson" "$geojson"
validator_require_file "$tmpdir/out.geojson"

jq -e '
  (.features | length) == 2
  and (.features[0].id == 11)
  and (.features[1].id == 22)
  and (.features[0].properties | has("n") | not)
  and (.features[0].properties.name == "alpha")
' "$tmpdir/out.geojson"
