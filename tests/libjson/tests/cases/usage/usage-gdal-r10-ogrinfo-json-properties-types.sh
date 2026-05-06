#!/usr/bin/env bash
# @testcase: usage-gdal-r10-ogrinfo-json-properties-types
# @title: GDAL ogrinfo -json reports per-property OGR field types
# @description: Builds a tiny GeoJSON layer with mixed string, integer and real properties and verifies ogrinfo -json (json-c serialised) reports a layers[0].fields entry per property with names mapped to OGR Integer/Integer64/Real/String types.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/mix.geojson" <<'JSON'
{
  "type": "FeatureCollection",
  "features": [
    {"type": "Feature",
     "properties": {"label": "alpha", "count": 1, "ratio": 0.25},
     "geometry": {"type": "Point", "coordinates": [0, 0]}},
    {"type": "Feature",
     "properties": {"label": "beta", "count": 2, "ratio": 0.50},
     "geometry": {"type": "Point", "coordinates": [1, 1]}}
  ]
}
JSON

ogrinfo -json -al -so "$tmpdir/mix.geojson" >"$tmpdir/out.json"
jq -e '
  .layers[0].fields
  | (type == "array")
  and ((map(.name) | sort) == ["count", "label", "ratio"])
  and ((map(select(.name == "label")) | first | .type) == "String")
  and ((map(select(.name == "count")) | first | .type) | test("Integer"))
  and ((map(select(.name == "ratio")) | first | .type) == "Real")
' "$tmpdir/out.json"
