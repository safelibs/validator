#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-group-a-count
# @title: gdal ogrinfo JSON group a count
# @description: Reads filtered GeoJSON metadata with ogrinfo -json and verifies the group-a predicate leaves exactly one feature.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-json-group-a-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -json -al -where "group = 'a'" "$geojson" >"$tmpdir/out.json"
jq -e '.layers[0].featureCount == 1' "$tmpdir/out.json"
