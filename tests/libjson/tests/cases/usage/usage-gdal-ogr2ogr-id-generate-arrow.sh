#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-id-generate-arrow
# @title: GDAL ogr2ogr -sql arrow numeric expression
# @description: Runs ogr2ogr with an SQL expression CAST to convert a string column into integer and writes a GeoJSON whose properties carry the numeric value.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"label":"42"},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"label":"7"},"geometry":{"type":"Point","coordinates":[1,1]}}
]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/out.geojson" "$tmpdir/in.geojson" \
  -sql "select CAST(label AS integer) as num from in"

python3 - "$tmpdir/out.geojson" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
nums = [f["properties"]["num"] for f in d["features"]]
if sorted(nums) != [7, 42]:
    raise SystemExit(f"expected [7,42], got {nums!r}")
PY
