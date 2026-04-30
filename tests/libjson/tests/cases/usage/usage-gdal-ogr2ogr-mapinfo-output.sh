#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-mapinfo-output
# @title: GDAL ogr2ogr MapInfo output
# @description: Converts a GeoJSON FeatureCollection to a MapInfo MIF/MID pair with ogr2ogr and verifies that the .mif sidecar declares MapInfo metadata and references the layer columns.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-mapinfo-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f 'MapInfo File' -dsco FORMAT=MIF "$tmpdir/out.mif" "$tmpdir/places.geojson" >"$tmpdir/ogr.log" 2>&1
validator_require_file "$tmpdir/out.mif"
validator_require_file "$tmpdir/out.mid"
validator_assert_contains "$tmpdir/out.mif" 'Version'
validator_assert_contains "$tmpdir/out.mif" 'Columns'
validator_assert_contains "$tmpdir/out.mif" 'name'
