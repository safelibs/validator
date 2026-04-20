#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

workload=${1:?missing GDAL workload}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

geojson="$tmpdir/points.geojson"
cat >"$geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha","value":1},"geometry":{"type":"Point","coordinates":[1,2]}},{"type":"Feature","properties":{"name":"beta","value":2},"geometry":{"type":"Point","coordinates":[3,4]}}]}
JSON

case "$workload" in
    ogrinfo-summary)
        ogrinfo "$geojson" -al -so | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'Feature Count: 2'
        ;;
    ogrinfo-filter)
        ogrinfo "$geojson" -al -where 'value=2' | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'beta'
        ;;
    ogr2ogr-copy)
        ogr2ogr -f GeoJSON "$tmpdir/copy.geojson" "$geojson"
        validator_assert_contains "$tmpdir/copy.geojson" 'beta'
        ;;
    ogr2ogr-where)
        ogr2ogr -f GeoJSON "$tmpdir/filtered.geojson" "$geojson" -where 'value=2'
        validator_assert_contains "$tmpdir/filtered.geojson" 'beta'
        if grep -Fq 'alpha' "$tmpdir/filtered.geojson"; then
            printf 'filtered GeoJSON unexpectedly retained alpha\n' >&2
            sed -n '1,120p' "$tmpdir/filtered.geojson" >&2
            exit 1
        fi
        ;;
    ogr2ogr-reproject)
        ogr2ogr -f GeoJSON "$tmpdir/reprojected.geojson" "$geojson" -s_srs EPSG:4326 -t_srs EPSG:3857
        jq -e '
          .type == "FeatureCollection"
          and (.features | length) > 0
          and any(.features[]; (.geometry.coordinates | length) > 0)
        ' "$tmpdir/reprojected.geojson"
        ;;
    ogr2ogr-csv)
        ogr2ogr -f CSV "$tmpdir/csv" "$geojson"
        validator_assert_contains "$tmpdir/csv/points.csv" 'alpha'
        validator_assert_contains "$tmpdir/csv/points.csv" 'beta'
        ;;
    ogr2ogr-gpkg)
        ogr2ogr -f GPKG "$tmpdir/out.gpkg" "$geojson"
        ogrinfo "$tmpdir/out.gpkg" -al -so | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'Feature Count: 2'
        ;;
    ogrinfo-sql)
        ogrinfo "$geojson" -sql 'SELECT name FROM points WHERE value = 1' | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'alpha'
        ;;
    ogrinfo-spatial-filter)
        ogrinfo "$geojson" -al -spat 0 0 2 3 | tee "$tmpdir/out"
        validator_assert_contains "$tmpdir/out" 'alpha'
        ;;
    gdalinfo-json-raster)
        raster=/usr/share/gdal/gdalicon.png
        validator_require_file "$raster"
        gdalinfo -json "$raster" >"$tmpdir/out.json"
        jq -e '.driverShortName == "PNG"' "$tmpdir/out.json"
        ;;
    *)
        printf 'unknown GDAL workload: %s\n' "$workload" >&2
        exit 2
        ;;
esac
