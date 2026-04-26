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
  usage-gdal-ogrinfo-layer-name)
    ogrinfo "$geojson" points -so | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Layer name: points'
    ;;
  usage-gdal-ogrinfo-sql-order)
    ogrinfo "$geojson" -sql 'SELECT name FROM points ORDER BY value DESC' >"$tmpdir/out"
    first=$(grep -F 'name (String)' "$tmpdir/out" | sed -n '1p')
    validator_assert_contains "$tmpdir/out" 'gamma'
    case "$first" in
      *gamma*) ;;
      *) printf 'unexpected first SQL row: %s\n' "$first" >&2; exit 1 ;;
    esac
    ;;
  usage-gdal-ogr2ogr-append-gpkg)
    ogr2ogr -f GPKG "$tmpdir/out.gpkg" "$geojson"
    ogr2ogr -append -f GPKG "$tmpdir/out.gpkg" "$geojson"
    ogrinfo "$tmpdir/out.gpkg" -al -so | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Feature Count: 6'
    ;;
  usage-gdal-ogr2ogr-coordinate-precision)
    ogr2ogr -f GeoJSON "$tmpdir/rounded.geojson" "$geojson" -lco COORDINATE_PRECISION=0
    jq -e 'all(.features[]; all(.geometry.coordinates[]; . == floor))' "$tmpdir/rounded.geojson"
    ;;
  usage-gdal-ogr2ogr-select-two-fields)
    ogr2ogr -f GeoJSON "$tmpdir/selected.geojson" "$geojson" -select name,group
    jq -e '(.features[0].properties.name == "alpha") and (.features[0].properties.group == "a") and (.features[0].properties.value == null)' "$tmpdir/selected.geojson"
    ;;
  usage-gdal-ogrinfo-json-all-features)
    ogrinfo -json -al "$geojson" >"$tmpdir/out.json"
    jq -e '.layers[0].name == "points" and .layers[0].featureCount == 3' "$tmpdir/out.json"
    ;;
  usage-gdal-gdalinfo-json-bands-count)
    raster=/usr/share/gdal/gdalicon.png
    validator_require_file "$raster"
    gdalinfo -json "$raster" >"$tmpdir/out.json"
    jq -e '.bands | length > 0' "$tmpdir/out.json"
    ;;
  usage-gdal-ogr2ogr-sql-rename-field)
    ogr2ogr -f GeoJSON "$tmpdir/renamed.geojson" "$geojson" -sql 'SELECT name AS label, value FROM points'
    jq -e '(.features[0].properties.label == "alpha") and (.features[0].properties.value == 1)' "$tmpdir/renamed.geojson"
    ;;
  usage-gdal-ogr2ogr-csv-headers)
    ogr2ogr -f CSV "$tmpdir/csv" "$geojson" -lco GEOMETRY=AS_WKT
    csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
    validator_require_file "$csv"
    header=$(sed -n '1p' "$csv")
    case "$header" in
      *WKT*name*value*group*) ;;
      *) printf 'unexpected CSV header: %s\n' "$header" >&2; exit 1 ;;
    esac
    ;;
  usage-gdalsrsinfo-epsg)
    gdalsrsinfo -o epsg EPSG:4326 >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'EPSG:4326'
    ;;
  *)
    printf 'unknown libjson additional usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
