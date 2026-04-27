#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1,"group":"a"},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2,"group":"b"},"geometry":{"type":"Point","coordinates":[3,4]}},{"type":"Feature","properties":{"name":"gamma","value":3,"group":"b"},"geometry":{"type":"Point","coordinates":[5,6]}}]}
JSON

case "$case_id" in
  usage-gdal-ogrinfo-sql-min-value)
    ogrinfo "$geojson" -dialect SQLITE -sql 'SELECT MIN(value) AS min_value FROM points' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'min_value'
    validator_assert_contains "$tmpdir/out" '1'
    ;;
  usage-gdal-ogrinfo-sql-max-feature-value)
    ogrinfo "$geojson" -dialect SQLITE -sql 'SELECT MAX(value) AS max_feature FROM points' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'max_feature'
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-gdal-ogr2ogr-select-name-only)
    ogr2ogr -f GeoJSON "$tmpdir/named.geojson" "$geojson" -select name
    jq -e '.features[0].properties | has("name") and (has("value") | not)' "$tmpdir/named.geojson"
    ;;
  usage-gdal-ogr2ogr-limit-two-features)
    ogr2ogr -f GeoJSON "$tmpdir/limit.geojson" "$geojson" -limit 2
    jq -e '(.features | length) == 2' "$tmpdir/limit.geojson"
    ;;
  usage-gdal-ogrinfo-json-feature-coords)
    ogrinfo -json -al -features "$geojson" >"$tmpdir/out.json"
    jq -e '.layers[0].features[1].geometry.coordinates == [3, 4]' "$tmpdir/out.json"
    ;;
  usage-gdal-ogr2ogr-where-name-equality)
    ogr2ogr -f GeoJSON "$tmpdir/named.geojson" "$geojson" -where "name = 'gamma'"
    jq -e '(.features | length) == 1 and .features[0].properties.name == "gamma"' "$tmpdir/named.geojson"
    ;;
  usage-gdal-ogrinfo-json-extent-bounds)
    ogrinfo -json -al "$geojson" >"$tmpdir/out.json"
    jq -e '.layers[0].geometryFields[0].extent == [1, 2, 5, 6]' "$tmpdir/out.json"
    ;;
  usage-gdal-gdalsrsinfo-wkt-wgs84)
    gdalsrsinfo -o wkt EPSG:4326 >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'WGS 84'
    ;;
  usage-gdal-gdalinfo-json-driver-png)
    raster=/usr/share/gdal/gdalicon.png
    validator_require_file "$raster"
    gdalinfo -json "$raster" >"$tmpdir/out.json"
    jq -e '.driverShortName == "PNG"' "$tmpdir/out.json"
    ;;
  usage-gdal-ogr2ogr-sql-order-desc)
    ogr2ogr -f GeoJSON "$tmpdir/order.geojson" "$geojson" -dialect SQLITE -sql 'SELECT name, value FROM points ORDER BY value DESC'
    jq -e '.features[0].properties.name == "gamma" and .features[2].properties.name == "alpha"' "$tmpdir/order.geojson"
    ;;
  *)
    printf 'unknown libjson tenth-batch usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
