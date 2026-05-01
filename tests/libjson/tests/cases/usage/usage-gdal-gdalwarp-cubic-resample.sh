#!/usr/bin/env bash
# @testcase: usage-gdal-gdalwarp-cubic-resample
# @title: GDAL gdalwarp cubic resampling
# @description: Resamples a small GeoTIFF with gdalwarp -r cubic to a coarser pixel size and verifies gdalinfo -json reports the requested coarser geo-transform pixel size on the resampled raster.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalwarp-cubic-resample"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/src.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/src.tif"

gdalwarp -r cubic -tr 0.5 0.5 -t_srs EPSG:4326 \
  "$tmpdir/src.tif" "$tmpdir/dst.tif" >"$tmpdir/warp.log" 2>&1
validator_require_file "$tmpdir/dst.tif"

gdalinfo -json "$tmpdir/dst.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (.geoTransform | length) == 6
  and ((.geoTransform[1]) == 0.5)
  and ((.geoTransform[5]) == -0.5)
' "$tmpdir/out.json"
