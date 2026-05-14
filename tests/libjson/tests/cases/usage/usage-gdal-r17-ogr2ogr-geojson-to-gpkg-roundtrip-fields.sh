#!/usr/bin/env bash
# @testcase: usage-gdal-r17-ogr2ogr-geojson-to-gpkg-roundtrip-fields
# @title: GDAL ogr2ogr GeoJSON to GPKG round-trip preserves field names
# @description: Converts a GeoJSON with named property fields into GPKG and back to GeoJSON via ogr2ogr; asserts both target fields ("alpha_name", "beta_value") survive the round trip via jq inspection of the final feature.
# @timeout: 120
# @tags: usage, gdal, geojson, gpkg, roundtrip
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"alpha_name":"first","beta_value":42},"geometry":{"type":"Point","coordinates":[0,0]}}
]}
JSON

ogr2ogr -f GPKG "$tmpdir/mid.gpkg" "$tmpdir/in.geojson"
validator_require_file "$tmpdir/mid.gpkg"

ogr2ogr -f GeoJSON "$tmpdir/out.geojson" "$tmpdir/mid.gpkg"
validator_require_file "$tmpdir/out.geojson"

jq -e '.features[0].properties | has("alpha_name") and has("beta_value")' "$tmpdir/out.geojson"
