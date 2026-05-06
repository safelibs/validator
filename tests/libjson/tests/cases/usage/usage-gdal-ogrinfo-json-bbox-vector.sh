#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-bbox-vector
# @title: GDAL ogrinfo -json geometryFields bbox
# @description: Runs ogrinfo -json -al on a Point GeoJSON dataset and verifies the layer geometryFields entry exposes a 4-element extent that bounds the inputs.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[-5,-3]}},
{"type":"Feature","properties":{"id":2},"geometry":{"type":"Point","coordinates":[10,7]}}
]}
JSON

ogrinfo -json -al "$tmpdir/in.geojson" >"$tmpdir/out.json"
python3 - "$tmpdir/out.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
layer = d["layers"][0]
gfields = layer.get("geometryFields", [])
if not gfields:
    raise SystemExit(f"no geometryFields in {list(layer)}")
extent = gfields[0].get("extent") or gfields[0].get("bbox")
if not extent or len(extent) != 4:
    raise SystemExit(f"bad extent: {extent!r}")
xmin, ymin, xmax, ymax = extent
if not (xmin <= -5 and ymin <= -3 and xmax >= 10 and ymax >= 7):
    raise SystemExit(f"extent does not bound inputs: {extent!r}")
PY
