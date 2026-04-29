#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-csv-as-xy
# @title: GDAL ogr2ogr CSV as XY
# @description: Exercises gdal ogr2ogr csv as xy through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-csv-as-xy"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

ogr2ogr -f CSV "$tmpdir/csv" "$geojson" -lco GEOMETRY=AS_XY
csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
validator_require_file "$csv"
header=$(sed -n '1p' "$csv")
case "$header" in
  *X*Y*name*value*group*) ;;
  *) printf 'unexpected CSV header: %s\n' "$header" >&2; exit 1 ;;
esac
