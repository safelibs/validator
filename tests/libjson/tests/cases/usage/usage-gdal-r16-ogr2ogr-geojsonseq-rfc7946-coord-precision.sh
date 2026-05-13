#!/usr/bin/env bash
# @testcase: usage-gdal-r16-ogr2ogr-geojsonseq-rfc7946-coord-precision
# @title: GDAL ogr2ogr -lco RFC7946=YES emits GeoJSONSeq with bounded coordinates
# @description: Converts a GeoJSON to GeoJSONSeq with -lco RFC7946=YES and asserts the resulting newline-delimited features parse as JSON via jq -e on each line, and the first emitted line's geometry coordinates length is 2.
# @timeout: 180
# @tags: usage, gdal, json, geojsonseq, rfc7946
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[1.5,2.5]}},
{"type":"Feature","properties":{"id":2},"geometry":{"type":"Point","coordinates":[3.5,4.5]}}
]}
JSON

ogr2ogr -f GeoJSONSeq -lco RFC7946=YES "$tmpdir/out.geojsonl" "$tmpdir/in.geojson"
test -s "$tmpdir/out.geojsonl"

# Each non-empty line must parse as JSON; first line must have a 2-element coords array.
line_count=0
while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  printf '%s' "$line" | jq -e . >/dev/null
  line_count=$((line_count + 1))
done <"$tmpdir/out.geojsonl"
test "$line_count" -eq 2

head -n 1 "$tmpdir/out.geojsonl" | jq -e '.geometry.coordinates | length == 2' >/dev/null
