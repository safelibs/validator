#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-scale-rescale
# @title: GDAL gdal_translate -scale rescaling
# @description: Rescales the bundled gdalicon raster's first band into the 0-100 range with gdal_translate -scale and verifies that gdalinfo -json -mm reports a computed maximum within the requested output range.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-scale-rescale"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -b 1 -ot Byte -scale 0 255 0 100 \
  "$raster" "$tmpdir/scaled.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/scaled.tif"

gdalinfo -json -mm "$tmpdir/scaled.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (.bands | length) >= 1
  and ((.bands[0].computedMax // .bands[0].max // 100) | tonumber) <= 100
  and ((.bands[0].computedMin // .bands[0].min // 0) | tonumber) >= 0
' "$tmpdir/out.json"
