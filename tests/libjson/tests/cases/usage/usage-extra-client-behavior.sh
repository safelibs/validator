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
  usage-gdal-ogrinfo-json-summary)
    ogrinfo -json "$geojson" >"$tmpdir/out.json"
    jq -e '.layers[0].featureCount == 3' "$tmpdir/out.json"
    ;;
  usage-gdal-ogrinfo-extent)
    ogrinfo "$geojson" -al -so | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Extent:'
    validator_assert_contains "$tmpdir/out" '(1.000000, 2.000000)'
    ;;
  usage-gdal-ogr2ogr-limit-geojson)
    ogr2ogr -f GeoJSON "$tmpdir/limited.geojson" "$geojson" -limit 1
    jq -e '.features | length == 1' "$tmpdir/limited.geojson"
    ;;
  usage-gdal-ogr2ogr-select-field)
    ogr2ogr -f GeoJSON "$tmpdir/selected.geojson" "$geojson" -select name
    jq -e '(.features[0].properties.name == "alpha") and (.features[0].properties.value == null)' "$tmpdir/selected.geojson"
    ;;
  usage-gdal-ogr2ogr-rename-layer)
    ogr2ogr -f GeoJSON "$tmpdir/renamed.geojson" "$geojson" -nln renamed_points
    ogrinfo "$tmpdir/renamed.geojson" -al -so | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'renamed_points'
    ;;
  usage-gdal-ogrinfo-sql-count)
    ogrinfo "$geojson" -sql "SELECT COUNT(*) AS total FROM points WHERE group = 'b'" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'total (Integer) = 2'
    ;;
  usage-gdal-gdalinfo-json-checksum)
    raster=/usr/share/gdal/gdalicon.png
    validator_require_file "$raster"
    gdalinfo -json -checksum "$raster" >"$tmpdir/out.json"
    jq -e '.driverShortName == "PNG" and (.bands[0].checksum | type == "number")' "$tmpdir/out.json"
    ;;
  usage-gdal-gdalsrsinfo-wkt)
    gdalsrsinfo -o wkt EPSG:4326 >"$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'WGS 84'
    ;;
  usage-gdal-ogr2ogr-geojsonseq)
    ogr2ogr -f GeoJSONSeq "$tmpdir/out.geojsons" "$geojson"
    validator_assert_contains "$tmpdir/out.geojsons" 'alpha'
    validator_assert_contains "$tmpdir/out.geojsons" 'gamma'
    ;;
  usage-gdal-ogrinfo-geom-no)
    ogrinfo "$geojson" -al -geom=NO | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'name (String) = beta'
    if grep -Fq 'POINT (' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-gdal-gdalsrsinfo-projjson)
    gdalsrsinfo -o projjson EPSG:4326 >"$tmpdir/out.json"
    jq -e '.type == "GeographicCRS"' "$tmpdir/out.json"
    ;;
  usage-gdal-gdalinfo-json-size)
    raster=/usr/share/gdal/gdalicon.png
    validator_require_file "$raster"
    gdalinfo -json "$raster" >"$tmpdir/out.json"
    jq -e '(.size[0] > 0) and (.size[1] > 0)' "$tmpdir/out.json"
    ;;
  usage-gdal-ogr2ogr-where-value)
    ogr2ogr -f GeoJSON "$tmpdir/filtered.geojson" "$geojson" -where "value >= 2"
    jq -e '.features | length == 2' "$tmpdir/filtered.geojson"
    ;;
  usage-gdal-ogr2ogr-sql-group-b)
    ogr2ogr -f GeoJSON "$tmpdir/group-b.geojson" "$geojson" -sql "SELECT name, value FROM points WHERE group = 'b'"
    jq -e '(.features | length == 2) and (.features[0].properties.name != null)' "$tmpdir/group-b.geojson"
    ;;
  usage-gdal-ogr2ogr-csv-export)
    ogr2ogr -f CSV "$tmpdir/csv" "$geojson" -lco GEOMETRY=AS_WKT
    csv=$(find "$tmpdir/csv" -name '*.csv' -print -quit)
    validator_require_file "$csv"
    validator_assert_contains "$csv" 'POINT'
    ;;
  usage-gdal-ogrinfo-where-name)
    ogrinfo "$geojson" -where "name = 'alpha'" -al | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'alpha'
    if grep -Fq 'gamma' "$tmpdir/out"; then exit 1; fi
    ;;
  usage-gdal-ogrinfo-json-where)
    ogrinfo -json "$geojson" -where "group = 'b'" >"$tmpdir/out.json"
    jq -e '.layers[0].featureCount == 2' "$tmpdir/out.json"
    ;;
  usage-gdal-ogr2ogr-multipoint)
    ogr2ogr -f GeoJSON "$tmpdir/multipoint.geojson" "$geojson" -nlt MULTIPOINT
    jq -e '.features[0].geometry.type == "MultiPoint"' "$tmpdir/multipoint.geojson"
    ;;
  usage-gdal-ogr2ogr-spatial-filter)
    ogr2ogr -f GeoJSON "$tmpdir/spatial.geojson" "$geojson" -spat 0 0 4 5
    jq -e '.features | length == 2' "$tmpdir/spatial.geojson"
    ;;
  usage-gdal-ogrinfo-summary-only)
    ogrinfo "$geojson" -al -so | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Feature Count: 3'
    ;;
  *)
    printf 'unknown libjson extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
