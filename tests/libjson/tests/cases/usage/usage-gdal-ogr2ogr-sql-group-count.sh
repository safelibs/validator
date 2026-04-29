#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-sql-group-count
# @title: gdal ogr2ogr SQL group count
# @description: Runs an ogr2ogr grouped SQL query over GeoJSON and verifies the grouped count results.
# @timeout: 180
# @tags: usage, gdal, geojson
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-sql-group-count"
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

ogr2ogr -f GeoJSON "$tmpdir/group-count.geojson" "$geojson" -dialect SQLITE -sql 'SELECT "group", COUNT(*) AS total FROM points GROUP BY "group" ORDER BY "group"'
jq -e '(.features | length) == 2 and (.features[0].properties.total == 1) and (.features[1].properties.total == 2)' "$tmpdir/group-count.geojson"
