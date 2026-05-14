#!/usr/bin/env bash
# @testcase: usage-gdal-r17-ogr2ogr-debug-on-completes-successfully
# @title: GDAL ogr2ogr --debug ON completes a GeoJSON copy with exit 0
# @description: Runs ogr2ogr --debug ON on a small GeoJSON copy and asserts the command exits zero and produces a parseable output GeoJSON, confirming debug-mode tracing does not regress the json-c output path.
# @timeout: 120
# @tags: usage, gdal, geojson, debug
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}}
]}
JSON

ogr2ogr --debug ON -f GeoJSON "$tmpdir/out.geojson" "$tmpdir/in.geojson" 2>"$tmpdir/dbg.log"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features | length >= 1' "$tmpdir/out.geojson"
