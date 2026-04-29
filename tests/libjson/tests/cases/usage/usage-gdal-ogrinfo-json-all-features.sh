#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-all-features
# @title: GDAL ogrinfo JSON all features
# @description: Emits JSON layer output from ogrinfo with -al and verifies the reported layer name and feature count.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-json-all-features"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -json -al "$geojson" >"$tmpdir/out.json"
jq -e '.layers[0].name == "points" and .layers[0].featureCount == 3' "$tmpdir/out.json"
