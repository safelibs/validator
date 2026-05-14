#!/usr/bin/env bash
# @testcase: usage-gdal-r18-ogrinfo-json-driver-geojson-name
# @title: GDAL ogrinfo -json reports driverShortName "GeoJSON" on a GeoJSON input
# @description: Runs ogrinfo -json on a 2-feature GeoJSON and asserts the json-c output contains a driverShortName equal to "GeoJSON", pinning the driver-identification field name and value emitted by Ubuntu 24.04 gdal.
# @timeout: 120
# @tags: usage, gdal, json, ogrinfo, driver, r18
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"id":2},"geometry":{"type":"Point","coordinates":[1,1]}}
]}
JSON

ogrinfo -json "$tmpdir/in.geojson" >"$tmpdir/info.json"
validator_require_file "$tmpdir/info.json"

jq -e '.. | objects | select(has("driverShortName")) | .driverShortName == "GeoJSON"' "$tmpdir/info.json" >/dev/null
