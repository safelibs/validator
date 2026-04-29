#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-feature-names
# @title: GDAL ogrinfo JSON feature names
# @description: Exercises gdal ogrinfo json feature names through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-json-feature-names"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -json -features -al "$geojson" >"$tmpdir/out.json"
jq -e '((.layers[0].features | map(.properties.name) | index("alpha")) != null) and ((.layers[0].features | map(.properties.name) | index("gamma")) != null)' "$tmpdir/out.json"
