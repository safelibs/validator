#!/usr/bin/env bash
# @testcase: usage-gdal-r17-ogr2ogr-sql-select-name-single-field
# @title: GDAL ogr2ogr SQL SELECT name returns a single-field GeoJSON
# @description: Runs ogr2ogr with an OGR SQL "SELECT name FROM ..." projection on a 2-field input and asserts the output GeoJSON features.properties contains only "name" — verifying SQL field projection through json-c-emitted output.
# @timeout: 120
# @tags: usage, gdal, sql, geojson
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","name":"src","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"x"},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"y"},"geometry":{"type":"Point","coordinates":[1,1]}}
]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/out.geojson" "$tmpdir/in.geojson" -sql "SELECT name FROM src"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features[0].properties | has("name") and (has("kind") | not)' "$tmpdir/out.geojson"
