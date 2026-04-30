#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-gpx-point
# @title: GDAL ogr2ogr GPX waypoint output
# @description: Converts an EPSG:4326 GeoJSON FeatureCollection of points to GPX with ogr2ogr and verifies the emitted file has a gpx XML root element and at least one waypoint.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-gpx-point"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
# GPX requires EPSG:4326; supply explicit CRS via crs member and use realistic
# lon/lat values. Each point becomes a GPX <wpt>.
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","crs":{"type":"name","properties":{"name":"urn:ogc:def:crs:OGC:1.3:CRS84"}},"features":[{"type":"Feature","properties":{"name":"alpha"},"geometry":{"type":"Point","coordinates":[-122.0,37.5]}},{"type":"Feature","properties":{"name":"beta"},"geometry":{"type":"Point","coordinates":[-73.9,40.7]}}]}
JSON

ogr2ogr -f GPX "$tmpdir/out.gpx" "$geojson" -nln waypoints \
  >"$tmpdir/ogr.log" 2>&1
validator_require_file "$tmpdir/out.gpx"

# GPX root element check (allow xmlns/version attributes after the tag name).
grep -Eq '<gpx[[:space:]>]' "$tmpdir/out.gpx" || {
  printf 'no <gpx ...> root element found:\n' >&2
  sed -n '1,20p' "$tmpdir/out.gpx" >&2
  exit 1
}

# At least one waypoint emitted.
grep -Eq '<wpt[[:space:]]' "$tmpdir/out.gpx" || {
  printf 'no <wpt ...> waypoint found:\n' >&2
  sed -n '1,40p' "$tmpdir/out.gpx" >&2
  exit 1
}
