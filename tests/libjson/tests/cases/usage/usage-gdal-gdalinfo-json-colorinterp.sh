#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-colorinterp
# @title: gdal gdalinfo JSON color interpretation
# @description: Reads raster JSON metadata with gdalinfo and verifies the first band reports a color interpretation string.
# @timeout: 180
# @tags: usage, gdal, raster
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-json-colorinterp"
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

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
gdalinfo -json "$raster" >"$tmpdir/out.json"
jq -e '(.bands[0].colorInterpretation | type) == "string" and (.bands[0].colorInterpretation | length) > 0' "$tmpdir/out.json"
