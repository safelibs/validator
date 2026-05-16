#!/usr/bin/env bash
# @testcase: usage-gdal-r21-ogr2ogr-geojson-bbox-length-four
# @title: GDAL ogr2ogr -lco WRITE_BBOX=YES feature bbox is a 4-number array
# @description: Builds a small CSV of 2D points, converts to GeoJSON with -lco WRITE_BBOX=YES, and asserts the per-feature bbox array json-c emits has exactly four numeric entries [minX,minY,maxX,maxY], pinning the 2D bbox layout for non-RFC7946 output.
# @timeout: 120
# @tags: usage, gdal, ogr2ogr, geojson, bbox, r21
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.csv" <<'CSV'
id,WKT
1,"POINT(1.5 2.5)"
2,"POINT(3.25 4.75)"
CSV
cat >"$tmpdir/in.csvt" <<'CSVT'
"Integer","String"
CSVT

ogr2ogr -f GeoJSON -lco WRITE_BBOX=YES "$tmpdir/out.geojson" "$tmpdir/in.csv"
python3 - "$tmpdir/out.geojson" <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
feats = d["features"]
assert feats, d
for f in feats:
    bbox = f.get("bbox")
    assert isinstance(bbox, list) and len(bbox) == 4, bbox
    for v in bbox:
        assert isinstance(v, (int, float)), bbox
PY
