#!/usr/bin/env bash
# @testcase: usage-gdal-r16-ogrinfo-json-driver-geojson-name
# @title: GDAL ogrinfo -json reports driver shortName GeoJSON
# @description: Runs ogrinfo -json -so on a GeoJSON file and asserts the json-c emitted driverShortName is exactly "GeoJSON" — pinning the driver-name field in the JSON summary.
# @timeout: 120
# @tags: usage, gdal, json, ogrinfo, driver
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}}
]}
JSON

ogrinfo -json -so "$tmpdir/in.geojson" >"$tmpdir/info.json"
jq -e '(.. | objects | select(has("driverShortName"))) | .driverShortName == "GeoJSON"' "$tmpdir/info.json"
