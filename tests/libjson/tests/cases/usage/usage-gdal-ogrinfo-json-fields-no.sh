#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-fields-no
# @title: GDAL ogrinfo JSON fields toggle
# @description: Runs ogrinfo -json -so over a 3-feature GeoJSON layer with three string properties and verifies the layer descriptor reports the matching feature count and field inventory.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-json-fields-no"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogrinfo -json -so "$geojson" >"$tmpdir/info.json"

# Tolerate both featureCount and feature_count layer keys across GDAL versions.
fcount='(.layers[0].featureCount // .layers[0].feature_count)'

# Layer must declare three features and three named string fields ("name",
# "value", "group"); compare names by sorted set so field order does not
# matter.
jq -e "$fcount == 3 and (.layers[0].fields | length) == 3" "$tmpdir/info.json"
jq -e '.layers[0].fields | map(.name) | sort == ["group","name","value"]' "$tmpdir/info.json"
