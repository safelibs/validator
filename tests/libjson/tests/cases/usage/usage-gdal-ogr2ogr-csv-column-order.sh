#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-csv-column-order
# @title: GDAL ogr2ogr CSV column order preserved
# @description: Exports a GeoJSON FeatureCollection whose property keys are deliberately not alphabetical to CSV via ogr2ogr and verifies the emitted header row preserves source field order rather than sorting it alphabetically.
# @timeout: 180
# @tags: usage, json, gdal
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-csv-column-order"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
# Deliberate non-alphabetical key order: zeta, alpha, mu.
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"zeta":1,"alpha":"a","mu":10},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"zeta":2,"alpha":"b","mu":20},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

ogr2ogr -f CSV "$tmpdir/csv" "$geojson"
csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
validator_require_file "$csv"

header=$(sed -n '1p' "$csv")
printf 'header=%s\n' "$header"

# Strip CR if any and split.
header_clean=${header%$'\r'}

# Find the index of each field in the header (1-based via awk).
zeta_idx=$(printf '%s' "$header_clean" | awk -F',' '{for(i=1;i<=NF;i++) if($i=="zeta") print i}')
alpha_idx=$(printf '%s' "$header_clean" | awk -F',' '{for(i=1;i<=NF;i++) if($i=="alpha") print i}')
mu_idx=$(printf '%s' "$header_clean" | awk -F',' '{for(i=1;i<=NF;i++) if($i=="mu") print i}')

[[ -n "$zeta_idx" && -n "$alpha_idx" && -n "$mu_idx" ]] || {
  printf 'expected header to contain zeta/alpha/mu, got: %s\n' "$header_clean" >&2
  exit 1
}

# Source order is zeta,alpha,mu — verify the CSV preserves it (not alphabetical
# alpha,mu,zeta).
if (( zeta_idx < alpha_idx && alpha_idx < mu_idx )); then
  :
else
  printf 'CSV column order not preserved: zeta=%s alpha=%s mu=%s (header=%s)\n' \
    "$zeta_idx" "$alpha_idx" "$mu_idx" "$header_clean" >&2
  exit 1
fi
