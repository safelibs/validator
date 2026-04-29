#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-select-field
# @title: GDAL ogr2ogr field select
# @description: Selects one GeoJSON attribute with ogr2ogr and verifies the omitted field is absent.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-select-field"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/selected.geojson" "$geojson" -select name
jq -e '(.features[0].properties.name == "alpha") and (.features[0].properties.value == null)' "$tmpdir/selected.geojson"
