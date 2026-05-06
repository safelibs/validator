#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-precision-rfc7946
# @title: GDAL ogr2ogr RFC7946 precision rounds coordinates
# @description: Runs ogr2ogr -f GeoJSON with -lco RFC7946=YES and -lco COORDINATE_PRECISION=2 and verifies coordinates in the output JSON are rounded to two decimals.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[12.345678,45.678912]}}
]}
JSON

ogr2ogr -f GeoJSON -lco RFC7946=YES -lco COORDINATE_PRECISION=2 "$tmpdir/out.geojson" "$tmpdir/in.geojson"

python3 - "$tmpdir/out.geojson" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
coords = d["features"][0]["geometry"]["coordinates"]
for c in coords:
    s = repr(c)
    if "." in s:
        decimals = len(s.split(".")[1])
        if decimals > 2:
            raise SystemExit(f"coordinate {c} has more than 2 decimals")
PY
