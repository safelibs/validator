#!/usr/bin/env bash
# @testcase: usage-gdal-r12-ogr2ogr-csv-newline-record-count
# @title: GDAL ogr2ogr converts a 3-feature GeoJSON to a CSV with one header + three rows
# @description: Writes a 3-feature GeoJSON FeatureCollection (which ogr2ogr ingests via json-c) and converts it with ogr2ogr to CSV, verifying the result file has exactly four newline-terminated lines (one header + three records).
# @timeout: 180
# @tags: usage, gdal, json, csv
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","val":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","val":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","val":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

ogr2ogr -f CSV "$tmpdir/out.csv" "$tmpdir/places.geojson" >"$tmpdir/log" 2>&1
validator_require_file "$tmpdir/out.csv"

lines=$(wc -l <"$tmpdir/out.csv")
[[ "$lines" == "4" ]] || { printf 'expected 4 lines, got %s\n' "$lines" >&2; cat "$tmpdir/out.csv" >&2; exit 1; }
