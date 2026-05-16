#!/usr/bin/env bash
# @testcase: usage-gdal-r21-ogrinfo-json-fields-nullable-flag
# @title: GDAL ogrinfo -json reports per-field nullable booleans
# @description: Generates a tiny GeoJSON feature with a single string attribute, runs ogrinfo -json -so, and asserts each field entry emitted by json-c has a "nullable" boolean key (typically true for GeoJSON), pinning the field schema JSON projection.
# @timeout: 120
# @tags: usage, gdal, ogrinfo, fields, nullable, r21
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
  {"type":"Feature","properties":{"name":"a"},"geometry":{"type":"Point","coordinates":[0,0]}}
]}
JSON

ogrinfo -json -so "$tmpdir/in.geojson" >"$tmpdir/out.json"
python3 - "$tmpdir/out.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
layers = d.get("layers", [])
assert layers, d
fields = layers[0].get("fields", [])
assert fields, layers[0]
for f in fields:
    assert "nullable" in f, f
    assert isinstance(f["nullable"], bool), f
PY
