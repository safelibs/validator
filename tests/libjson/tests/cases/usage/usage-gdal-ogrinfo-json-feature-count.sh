#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-feature-count
# @title: GDAL ogrinfo -json featureCount
# @description: Runs ogrinfo -json on a 4-feature GeoJSON layer and verifies the reported featureCount equals 4.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"id":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"id":3},"geometry":{"type":"Point","coordinates":[2,2]}},
{"type":"Feature","properties":{"id":4},"geometry":{"type":"Point","coordinates":[3,3]}}
]}
JSON

ogrinfo -json "$tmpdir/in.geojson" >"$tmpdir/out.json"
python3 - "$tmpdir/out.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
layers = d.get("layers", [])
if not layers:
    raise SystemExit(f"no layers, keys {list(d)}")
count = layers[0].get("featureCount")
if count != 4:
    raise SystemExit(f"expected featureCount 4, got {count!r}")
PY
