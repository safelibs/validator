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
  usage-gdal-ogrinfo-sql-sum-value)
    ogrinfo "$geojson" -dialect SQLITE -sql 'SELECT SUM(value) AS total_value FROM points' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'total_value'
    validator_assert_contains "$tmpdir/out" '6'
    ;;
  usage-gdal-ogr2ogr-sql-double-value)
    ogr2ogr -f GeoJSON "$tmpdir/double.geojson" "$geojson" -dialect SQLITE -sql 'SELECT name, value * 2 AS doubled FROM points ORDER BY value'
    jq -e '.features[0].properties.doubled == 2 and .features[2].properties.doubled == 6' "$tmpdir/double.geojson"
    ;;
  usage-gdal-ogr2ogr-field-type-string-integer)
    ogr2ogr -f GeoJSON "$tmpdir/string.geojson" "$geojson" -fieldTypeToString Integer
    jq -e '.features[0].properties.value == "1"' "$tmpdir/string.geojson"
    ;;
  usage-gdal-ogr2ogr-gpkg-renamed-layer)
    ogr2ogr -f GPKG "$tmpdir/out.gpkg" "$geojson" -nln renamed_points_gpkg
    ogrinfo "$tmpdir/out.gpkg" renamed_points_gpkg -so >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Layer name: renamed_points_gpkg'
    ;;
  usage-gdal-ogrinfo-json-so-fields)
    ogrinfo -json -so "$geojson" >"$tmpdir/out.json"
    jq -e '.layers[0].featureCount == 3 and (.layers[0].fields | length) == 3' "$tmpdir/out.json"
    ;;
  usage-gdal-gdalinfo-json-files-list)
    raster=/usr/share/gdal/gdalicon.png
    validator_require_file "$raster"
    gdalinfo -json "$raster" >"$tmpdir/out.json"
    jq -e '(.files | length) > 0' "$tmpdir/out.json"
    ;;
  usage-gdalsrsinfo-mapinfo-wgs84)
    gdalsrsinfo -o mapinfo EPSG:4326 >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Earth Projection'
    ;;
  usage-gdal-ogrinfo-sql-between-values)
    ogrinfo "$geojson" -dialect SQLITE -sql 'SELECT name FROM points WHERE value BETWEEN 2 AND 3 ORDER BY value' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'beta'
    validator_assert_contains "$tmpdir/out" 'gamma'
    ;;
  usage-gdal-ogr2ogr-csv-xy-headers)
    ogr2ogr -f CSV "$tmpdir/csv" "$geojson" -lco GEOMETRY=AS_XY
    csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
    validator_require_file "$csv"
    header=$(sed -n '1p' "$csv")
    case "$header" in
      *X*Y*name*value*group*) ;;
      *) printf 'unexpected CSV header: %s\n' "$header" >&2; exit 1 ;;
    esac
    ;;
  usage-gdal-ogrinfo-json-group-a-count)
    ogrinfo -json -al -where "group = 'a'" "$geojson" >"$tmpdir/out.json"
    jq -e '.layers[0].featureCount == 1' "$tmpdir/out.json"
    ;;
  *)
    printf 'unknown libjson expanded usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
