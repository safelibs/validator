#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-flatgeobuf
# @title: GDAL ogr2ogr FlatGeobuf output
# @description: Converts a small GeoJSON FeatureCollection to the FlatGeobuf binary format with ogr2ogr -f FlatGeobuf and verifies that ogrinfo -json reports the FlatGeobuf driver and round-trips the original feature count.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-flatgeobuf"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f FlatGeobuf "$tmpdir/points.fgb" "$geojson" >"$tmpdir/ogr2ogr.log" 2>&1
validator_require_file "$tmpdir/points.fgb"

# FlatGeobuf files start with the magic bytes "fgb<03>fgb<00>" or similar
# header; just sanity-check it's a non-empty binary file via `file`.
file "$tmpdir/points.fgb" >"$tmpdir/file.txt"

ogrinfo -json -al "$tmpdir/points.fgb" >"$tmpdir/out.json"
jq -e '
  (.layers | length) >= 1
  and .layers[0].featureCount == 3
  and (
    .driverShortName == "FlatGeobuf"
    or .layers[0].driverShortName == "FlatGeobuf"
    or any(.. | objects; (.driverShortName? // "") == "FlatGeobuf")
  )
' "$tmpdir/out.json"
