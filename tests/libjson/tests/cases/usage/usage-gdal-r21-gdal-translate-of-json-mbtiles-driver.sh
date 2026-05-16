#!/usr/bin/env bash
# @testcase: usage-gdal-r21-gdal-translate-of-json-mbtiles-driver
# @title: GDAL gdalinfo -json with -mdd all reports raster metadata domains
# @description: Creates a GTiff with a known metadata item via gdal_translate -mo, runs gdalinfo -json -mdd all, and asserts the metadata object emitted by json-c contains the configured FOO key in the default domain, pinning the metadata-domain JSON projection.
# @timeout: 120
# @tags: usage, gdal, gdalinfo, metadata, mdd, r21
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdal_create -of GTiff -outsize 8 8 -bands 1 -ot Byte "$tmpdir/src.tif" >/dev/null
gdal_translate -of GTiff -mo FOO=bar "$tmpdir/src.tif" "$tmpdir/tagged.tif" >/dev/null

gdalinfo -json -mdd all "$tmpdir/tagged.tif" >"$tmpdir/out.json"
python3 - "$tmpdir/out.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
md = d.get("metadata", {})
default = md.get("", {})
assert default.get("FOO") == "bar", md
PY
