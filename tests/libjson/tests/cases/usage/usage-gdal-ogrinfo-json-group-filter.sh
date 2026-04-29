#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-group-filter
# @title: GDAL ogrinfo JSON group filter
# @description: Exercises gdal ogrinfo json group filter through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-json-group-filter"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -json -al -where "group = 'b'" "$geojson" >"$tmpdir/out.json"
jq -e '.layers[0].featureCount == 2' "$tmpdir/out.json"
