#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/places.geojson" <<'JSON'
{"type":"FeatureCollection","features":[
{"type":"Feature","properties":{"name":"alpha","kind":"park","value":1},"geometry":{"type":"Point","coordinates":[0,0]}},
{"type":"Feature","properties":{"name":"beta","kind":"road","value":2},"geometry":{"type":"Point","coordinates":[1,1]}},
{"type":"Feature","properties":{"name":"gamma","kind":"park","value":3},"geometry":{"type":"Point","coordinates":[2,2]}}
]}
JSON

case "$case_id" in
  usage-gdal-batch11-ogrinfo-feature-count)
    ogrinfo -ro -al -so "$tmpdir/places.geojson" >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Feature Count: 3'
    ;;
  usage-gdal-batch11-ogrinfo-where-park)
    ogrinfo -ro "$tmpdir/places.geojson" -where "kind = 'park'" places >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    validator_assert_contains "$tmpdir/out" 'gamma'
    ;;
  usage-gdal-batch11-ogr2ogr-select-name)
    ogr2ogr -f GeoJSON "$tmpdir/names.geojson" "$tmpdir/places.geojson" -select name
    validator_assert_contains "$tmpdir/names.geojson" '"name"'
    if grep -Fq '"kind"' "$tmpdir/names.geojson"; then exit 1; fi
    ;;
  usage-gdal-batch11-ogr2ogr-csv-wkt)
    ogr2ogr -f CSV "$tmpdir/csv" "$tmpdir/places.geojson" -lco GEOMETRY=AS_WKT
    validator_assert_contains "$tmpdir/csv/places.csv" 'POINT'
    validator_assert_contains "$tmpdir/csv/places.csv" 'alpha'
    ;;
  usage-gdal-batch11-ogr2ogr-webmercator)
    ogr2ogr -f GeoJSON "$tmpdir/webm.geojson" "$tmpdir/places.geojson" -t_srs EPSG:3857
    validator_assert_contains "$tmpdir/webm.geojson" 'FeatureCollection'
    ;;
  usage-gdal-batch11-ogrinfo-sql-distinct-kind)
    ogrinfo -ro "$tmpdir/places.geojson" -dialect SQLite -sql 'SELECT DISTINCT kind FROM places ORDER BY kind' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'kind (String) = park'
    validator_assert_contains "$tmpdir/out" 'kind (String) = road'
    ;;
  usage-gdal-batch11-ogr2ogr-where-value)
    ogr2ogr -f GeoJSON "$tmpdir/filtered.geojson" "$tmpdir/places.geojson" -where 'value >= 2'
    jq -e '.features | length == 2' "$tmpdir/filtered.geojson"
    ;;
  usage-gdal-batch11-ogr2ogr-geojsonseq)
    ogr2ogr -f GeoJSONSeq "$tmpdir/out.geojsons" "$tmpdir/places.geojson"
    validator_assert_contains "$tmpdir/out.geojsons" 'Feature'
    ;;
  usage-gdal-batch11-ogr2ogr-gml-output)
    ogr2ogr -f GML "$tmpdir/out.gml" "$tmpdir/places.geojson"
    validator_assert_contains "$tmpdir/out.gml" '<gml:'
    ;;
  usage-gdal-batch11-ogr2ogr-sql-order-asc)
    ogr2ogr -f GeoJSON "$tmpdir/sorted.geojson" "$tmpdir/places.geojson" -dialect SQLite -sql 'SELECT * FROM places ORDER BY value ASC'
    jq -e '.features[0].properties.name == "alpha"' "$tmpdir/sorted.geojson"
    ;;
  *)
    printf 'unknown libjson eleventh-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
