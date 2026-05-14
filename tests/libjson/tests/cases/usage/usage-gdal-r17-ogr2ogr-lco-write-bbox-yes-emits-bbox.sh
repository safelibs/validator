#!/usr/bin/env bash
# @testcase: usage-gdal-r17-ogr2ogr-lco-write-bbox-yes-emits-bbox
# @title: GDAL ogr2ogr -lco WRITE_BBOX=YES emits feature bbox in GeoJSON
# @description: Re-writes a GeoJSON via ogr2ogr -f GeoJSON -lco WRITE_BBOX=YES and asserts the resulting feature objects include a "bbox" 4-element array, pinning GDAL's per-feature bbox layer-creation option round-trip.
# @timeout: 120
# @tags: usage, gdal, geojson, bbox
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Polygon","coordinates":[[[0,0],[1,0],[1,1],[0,1],[0,0]]]}}
]}
JSON

ogr2ogr -f GeoJSON -lco WRITE_BBOX=YES "$tmpdir/out.geojson" "$tmpdir/in.geojson"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features[0].bbox | length == 4' "$tmpdir/out.geojson"
