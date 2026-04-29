#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-rfc7946
# @title: GDAL ogr2ogr RFC 7946 output
# @description: Exercises gdal ogr2ogr rfc 7946 output through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-rfc7946"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/rfc7946.geojson" "$geojson" -lco RFC7946=YES
jq -e '.type == "FeatureCollection" and (.features | length) == 3' "$tmpdir/rfc7946.geojson"
