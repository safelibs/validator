#!/usr/bin/env bash
# @testcase: usage-gdal-r16-ogr2ogr-sql-where-id-gt1-feature-count
# @title: GDAL ogr2ogr SELECT WHERE id>1 yields 2 features
# @description: Runs ogr2ogr with -sql "SELECT * FROM in WHERE id > 1" on a 3-feature GeoJSON and asserts the output GeoJSON's features array has length 2 via jq -e.
# @timeout: 180
# @tags: usage, gdal, json, sql, where
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"id":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"id":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/out.geojson" "$tmpdir/in.geojson" -sql "SELECT * FROM \"in\" WHERE id > 1"
jq -e '.features | length == 2' "$tmpdir/out.geojson"
