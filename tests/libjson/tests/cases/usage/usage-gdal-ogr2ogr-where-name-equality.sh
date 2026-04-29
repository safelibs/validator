#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-where-name-equality
# @title: gdal ogr2ogr where name equality
# @description: Filters GeoJSON output with ogr2ogr -where on a name equality predicate and verifies only the matching feature is retained.
# @timeout: 180
# @tags: usage, gdal, geojson
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-where-name-equality"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/named.geojson" "$geojson" -where "name = 'gamma'"
jq -e '(.features | length) == 1 and .features[0].properties.name == "gamma"' "$tmpdir/named.geojson"
