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
  usage-gdal-ogrinfo-json-feature-names)
    ogrinfo -json -features -al "$geojson" >"$tmpdir/out.json"
    jq -e '((.layers[0].features | map(.properties.name) | index("alpha")) != null) and ((.layers[0].features | map(.properties.name) | index("gamma")) != null)' "$tmpdir/out.json"
    ;;
  usage-gdal-ogr2ogr-sql-max-value)
    ogr2ogr -f GeoJSON "$tmpdir/max.geojson" "$geojson" -dialect SQLITE -sql 'SELECT MAX(value) AS max_value FROM points'
    jq -e '.features[0].properties.max_value == 3' "$tmpdir/max.geojson"
    ;;
  usage-gdal-ogr2ogr-rfc7946)
    ogr2ogr -f GeoJSON "$tmpdir/rfc7946.geojson" "$geojson" -lco RFC7946=YES
    jq -e '.type == "FeatureCollection" and (.features | length) == 3' "$tmpdir/rfc7946.geojson"
    ;;
  usage-gdal-ogrinfo-sql-max-value)
    ogrinfo "$geojson" -sql 'SELECT MAX(value) AS max_value FROM points' >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'max_value'
    validator_assert_contains "$tmpdir/out" '3'
    ;;
  usage-gdal-gdalinfo-json-corner-coordinates)
    raster=/usr/share/gdal/gdalicon.png
    validator_require_file "$raster"
    gdalinfo -json "$raster" >"$tmpdir/out.json"
    jq -e '(.cornerCoordinates.upperLeft | length) == 2 and (.cornerCoordinates.lowerRight | length) == 2' "$tmpdir/out.json"
    ;;
  usage-gdal-gdalinfo-json-driver-long-name)
    raster=/usr/share/gdal/gdalicon.png
    validator_require_file "$raster"
    gdalinfo -json "$raster" >"$tmpdir/out.json"
    jq -e '(.driverLongName | type) == "string" and (.driverLongName | length) > 0' "$tmpdir/out.json"
    ;;
  usage-gdal-ogr2ogr-csv-as-xy)
    ogr2ogr -f CSV "$tmpdir/csv" "$geojson" -lco GEOMETRY=AS_XY
    csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
    validator_require_file "$csv"
    header=$(sed -n '1p' "$csv")
    case "$header" in
      *X*Y*name*value*group*) ;;
      *) printf 'unexpected CSV header: %s\n' "$header" >&2; exit 1 ;;
    esac
    ;;
  usage-gdal-ogr2ogr-order-desc)
    ogr2ogr -f GeoJSON "$tmpdir/ordered.geojson" "$geojson" -dialect SQLITE -sql 'SELECT name, value FROM points ORDER BY value DESC'
    jq -e '.features[0].properties.name == "gamma"' "$tmpdir/ordered.geojson"
    ;;
  usage-gdalsrsinfo-projjson-id)
    gdalsrsinfo -o projjson EPSG:3857 >"$tmpdir/out.json"
    jq -e '.id.code == 3857' "$tmpdir/out.json"
    ;;
  usage-gdal-ogrinfo-json-group-filter)
    ogrinfo -json -al -where "group = 'b'" "$geojson" >"$tmpdir/out.json"
    jq -e '.layers[0].featureCount == 2' "$tmpdir/out.json"
    ;;
  *)
    printf 'unknown libjson even-more usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
