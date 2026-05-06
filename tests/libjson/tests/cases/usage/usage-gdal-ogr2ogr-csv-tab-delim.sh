#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-csv-tab-delim
# @title: GDAL ogr2ogr CSV tab separator
# @description: Converts a GeoJSON layer to CSV with -lco SEPARATOR=TAB and verifies the header line is tab-delimited.
# @timeout: 180
# @tags: usage, gdal, csv
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[0,0]}}
]}
JSON

ogr2ogr -f CSV -lco SEPARATOR=TAB "$tmpdir/out" "$tmpdir/in.geojson"
csv=$(ls "$tmpdir/out"/*.csv | head -n1)
validator_require_file "$csv"
head -n1 "$csv" >"$tmpdir/header"
# Header should contain a tab character.
python3 - "$tmpdir/header" <<'PY'
import sys
h = open(sys.argv[1]).read().rstrip("\n")
if "\t" not in h:
    raise SystemExit(f"no tab in header: {h!r}")
PY
