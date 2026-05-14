#!/usr/bin/env bash
# @testcase: usage-gdal-r18-ogrinfo-json-fields-include-id-name
# @title: GDAL ogrinfo -json reports both id and name fields on the source layer
# @description: Runs ogrinfo -json -so on a GeoJSON whose features carry id and name properties and asserts the json-c output enumerates field entries whose names contain both "id" and "name", pinning the schema discovery output.
# @timeout: 120
# @tags: usage, gdal, json, ogrinfo, fields, r18
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1,"name":"alpha"},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"id":2,"name":"beta"},"geometry":{"type":"Point","coordinates":[1,1]}}
]}
JSON

ogrinfo -json -so "$tmpdir/in.geojson" >"$tmpdir/info.json"
validator_require_file "$tmpdir/info.json"

jq -e '[.. | objects | select(.name? != null) | .name] | (any(. == "id") and any(. == "name"))' "$tmpdir/info.json" >/dev/null
