#!/usr/bin/env bash
# @testcase: usage-gdal-r21-gdalinfo-json-wgs84-wkt-substring
# @title: GDAL gdalinfo -json coordinateSystem.wkt contains WGS 84 datum string
# @description: Creates a small WGS84-anchored GTiff via gdal_create, runs gdalinfo -json, and asserts .coordinateSystem.wkt is a string emitted by json-c containing the WGS 84 datum identifier, pinning the SRS WKT field shape in the JSON document.
# @timeout: 120
# @tags: usage, gdal, gdalinfo, coordinate-system, wkt, r21
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdal_create -of GTiff -outsize 8 8 -bands 1 -ot Byte -a_srs EPSG:4326 \
  -a_ullr -10 10 10 -10 "$tmpdir/in.tif" >/dev/null

gdalinfo -json "$tmpdir/in.tif" >"$tmpdir/out.json"
python3 - "$tmpdir/out.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
wkt = d["coordinateSystem"]["wkt"]
assert isinstance(wkt, str) and len(wkt) > 0
assert "WGS 84" in wkt or "WGS_1984" in wkt, wkt[:200]
PY
