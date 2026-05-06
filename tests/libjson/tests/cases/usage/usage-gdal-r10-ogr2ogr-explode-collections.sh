#!/usr/bin/env bash
# @testcase: usage-gdal-r10-ogr2ogr-explode-collections
# @title: GDAL ogr2ogr explodecollections splits multipoint
# @description: Converts a GeoJSON multipoint feature with three component points to a per-point feature collection via ogr2ogr -explodecollections and verifies json-c emits three Point features in the resulting GeoJSON.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/multi.geojson" <<'JSON'
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {"name": "trio"},
      "geometry": {"type": "MultiPoint", "coordinates": [[0, 0], [1, 1], [2, 2]]}
    }
  ]
}
JSON

ogr2ogr -f GeoJSON -explodecollections "$tmpdir/exploded.geojson" "$tmpdir/multi.geojson"
jq -e '
  (.type == "FeatureCollection")
  and ((.features | length) == 3)
  and (all(.features[]; .geometry.type == "Point"))
  and (all(.features[]; .properties.name == "trio"))
' "$tmpdir/exploded.geojson"
