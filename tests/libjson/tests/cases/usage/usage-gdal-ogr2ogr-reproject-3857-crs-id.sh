#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-reproject-3857-crs-id
# @title: GDAL ogr2ogr reproject 3857 CRS identifier
# @description: Reprojects a GeoJSON layer to EPSG:3857 with ogr2ogr and verifies that ogrinfo -json reports the EPSG authority and code in the resulting CRS metadata.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-reproject-3857-crs-id"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/points.geojson"
cat >"$src" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogr2ogr -f GeoJSON "$tmpdir/webm.geojson" "$src" -s_srs EPSG:4326 -t_srs EPSG:3857
ogrinfo -json -al -so "$tmpdir/webm.geojson" >"$tmpdir/out.json"

# PROJJSON identifier shape varies across GDAL releases (id may be an
# object, array of objects, or sit under base_crs/source_crs). Walk the
# layer's coordinateSystem.projjson subtree and require some node to yield
# the EPSG authority paired with code 3857.
jq -e '
  [.layers[0].geometryFields[0].coordinateSystem.projjson | ..]
  | map(select(type == "object" and has("authority") and has("code")))
  | any(.[]; .authority == "EPSG" and (.code | tostring) == "3857")
' "$tmpdir/out.json"
