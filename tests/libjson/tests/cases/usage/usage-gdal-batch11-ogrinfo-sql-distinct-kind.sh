#!/usr/bin/env bash
# @testcase: usage-gdal-batch11-ogrinfo-sql-distinct-kind
# @title: GDAL ogrinfo SQL distinct kind
# @description: Runs a SQLite DISTINCT query over a GeoJSON layer and checks the emitted kind values.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-batch11-ogrinfo-sql-distinct-kind"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogrinfo -ro "$tmpdir/places.geojson" -dialect SQLite -sql 'SELECT DISTINCT kind FROM places ORDER BY kind' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'kind (String) = park'
validator_assert_contains "$tmpdir/out" 'kind (String) = road'
