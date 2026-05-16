#!/usr/bin/env bash
# @testcase: usage-gdal-r21-gdalmdiminfo-default-json-shape
# @title: GDAL gdalmdiminfo emits json-c JSON with type=group on a GTiff dataset
# @description: Creates a small Zarr dataset via gdal_create then runs gdalmdiminfo against it, asserting the json-c-emitted output parses cleanly and contains a top-level "type" key set to the string "group" and driver "Zarr", pinning the multi-dim info root document shape.
# @timeout: 120
# @tags: usage, gdal, gdalmdiminfo, json, r21
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdal_create -of Zarr -outsize 8 8 -bands 1 -ot Byte "$tmpdir/in.zarr" >/dev/null
validator_require_dir "$tmpdir/in.zarr"

gdalmdiminfo "$tmpdir/in.zarr" >"$tmpdir/out.json"
validator_require_file "$tmpdir/out.json"

python3 - "$tmpdir/out.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
assert isinstance(d, dict), type(d)
assert d.get("type") == "group", d.get("type")
assert d.get("driver") == "Zarr", d.get("driver")
PY
