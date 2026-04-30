#!/usr/bin/env bash
# @testcase: usage-gdal-gdaltindex-geojson
# @title: GDAL gdaltindex GeoJSON tile index
# @description: Builds a GeoJSON tile index with gdaltindex over a small raster fixture and verifies the resulting FeatureCollection records the input filename in its location attribute.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdaltindex-geojson"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# Stamp the raster with a real geotransform + EPSG:4326 SRS so gdaltindex can
# build a tile index over a properly georeferenced input.
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/icon.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/icon.tif"

cd "$tmpdir"
gdaltindex -f GeoJSON tiles.geojson icon.tif >"$tmpdir/tindex.log" 2>&1
validator_require_file "$tmpdir/tiles.geojson"

# GDAL records the source raster path in a property whose key varies across
# versions ("location", "src_path", "PATH", "location"). Check that the
# FeatureCollection has at least one feature whose properties (recursively)
# include a string ending in icon.tif.
jq -e '
  .type == "FeatureCollection"
  and (.features | length) >= 1
  and any(
    .features[];
    [.properties | .. | strings] | any(. | endswith("icon.tif"))
  )
' "$tmpdir/tiles.geojson"
