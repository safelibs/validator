#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-json-driver-name
# @title: GDAL ogrinfo -json reports driver shortName
# @description: Runs ogrinfo -json on a small GeoJSON layer and verifies the reported driver shortName is GeoJSON.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"id":1},"geometry":{"type":"Point","coordinates":[0,0]}}]}
JSON

ogrinfo -json "$tmpdir/in.geojson" >"$tmpdir/out.json"
python3 - "$tmpdir/out.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
short = d.get("driverShortName") or d.get("driver", {}).get("shortName")
if short != "GeoJSON":
    raise SystemExit(f"unexpected driverShortName: {short!r} in keys {list(d)}")
PY
