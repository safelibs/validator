#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-csv-group-b
# @title: gdal ogr2ogr CSV group filter
# @description: Exports a filtered GeoJSON subset to CSV with ogr2ogr and verifies only the selected group rows remain.
# @timeout: 180
# @tags: usage, gdal, geojson
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-csv-group-b"
tmpdir=$(mktemp -d)
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -rf "$tmpdir"
}
trap cleanup EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

start_ttyd() {
  local port=$((31000 + RANDOM % 3000))
  ttyd -i 127.0.0.1 -p "$port" bash -lc 'printf validator-ttyd' >"$tmpdir/ttyd.log" 2>&1 &
  pid=$!
  for _ in $(seq 1 40); do
    if curl -fsS "http://127.0.0.1:$port/" >"$tmpdir/page.html" 2>"$tmpdir/curl.err"; then
      printf '%s\n' "$port"
      return 0
    fi
    sleep 0.25
  done
  sed -n '1,120p' "$tmpdir/ttyd.log" >&2 || true
  exit 1
}

ogr2ogr -f CSV "$tmpdir/csv" "$geojson" -where "group = 'b'" -lco GEOMETRY=AS_WKT
csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
validator_require_file "$csv"
validator_assert_contains "$csv" 'beta'
validator_assert_contains "$csv" 'gamma'
if grep -Fq 'alpha' "$csv"; then
  printf 'CSV unexpectedly retained alpha\n' >&2
  exit 1
fi
