#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

case "$case_id" in
  usage-ttyd-loopback-content-type)
    port=$(start_ttyd)
    curl -fsSI "http://127.0.0.1:$port/" >"$tmpdir/headers"
    validator_assert_contains "$tmpdir/headers" 'content-type: text/html'
    ;;
  usage-ttyd-loopback-websocket-script)
    port=$(start_ttyd)
    validator_assert_contains "$tmpdir/page.html" '/ws'
    ;;
  usage-ttyd-loopback-xterm-asset)
    port=$(start_ttyd)
    validator_assert_contains "$tmpdir/page.html" 'xterm'
    ;;
  usage-gdal-ogrinfo-sql-average-value)
    ogrinfo "$geojson" -sql 'SELECT AVG(value) AS avg_value FROM points' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'avg_value'
    validator_assert_contains "$tmpdir/out" '2'
    ;;
  usage-gdal-ogrinfo-json-geometry-type)
    ogrinfo -json -al "$geojson" >"$tmpdir/out.json"
    jq -e '.layers[0].geometryFields[0].type == "Point"' "$tmpdir/out.json"
    ;;
  usage-gdal-ogr2ogr-sql-group-count)
    ogr2ogr -f GeoJSON "$tmpdir/group-count.geojson" "$geojson" -dialect SQLITE -sql 'SELECT "group", COUNT(*) AS total FROM points GROUP BY "group" ORDER BY "group"'
    jq -e '(.features | length) == 2 and (.features[0].properties.total == 1) and (.features[1].properties.total == 2)' "$tmpdir/group-count.geojson"
    ;;
  usage-gdal-ogr2ogr-csv-group-b)
    ogr2ogr -f CSV "$tmpdir/csv" "$geojson" -where "group = 'b'" -lco GEOMETRY=AS_WKT
    csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
    validator_require_file "$csv"
    validator_assert_contains "$csv" 'beta'
    validator_assert_contains "$csv" 'gamma'
    if grep -Fq 'alpha' "$csv"; then
      printf 'CSV unexpectedly retained alpha\n' >&2
      exit 1
    fi
    ;;
  usage-gdal-gdalsrsinfo-proj4)
    gdalsrsinfo -o proj4 EPSG:4326 >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" '+proj=longlat'
    ;;
  usage-gdal-gdalsrsinfo-xml)
    gdalsrsinfo -o xml EPSG:4326 >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'WGS 84'
    ;;
  usage-gdal-gdalinfo-json-colorinterp)
    raster=/usr/share/gdal/gdalicon.png
    validator_require_file "$raster"
    gdalinfo -json "$raster" >"$tmpdir/out.json"
    jq -e '(.bands[0].colorInterpretation | type) == "string" and (.bands[0].colorInterpretation | length) > 0' "$tmpdir/out.json"
    ;;
  *)
    printf 'unknown libjson further usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
