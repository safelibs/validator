#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-kml-output
# @title: GDAL ogr2ogr KML output
# @description: Converts a GeoJSON FeatureCollection to KML with ogr2ogr and verifies the resulting file declares the KML namespace and carries a Placemark for one of the input features.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-kml-output"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f KML "$tmpdir/out.kml" "$tmpdir/places.geojson" >"$tmpdir/ogr.log" 2>&1
validator_require_file "$tmpdir/out.kml"
validator_assert_contains "$tmpdir/out.kml" 'http://www.opengis.net/kml'
validator_assert_contains "$tmpdir/out.kml" '<Placemark>'
validator_assert_contains "$tmpdir/out.kml" 'alpha'
