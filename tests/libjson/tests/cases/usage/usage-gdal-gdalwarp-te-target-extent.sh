#!/usr/bin/env bash
# @testcase: usage-gdal-gdalwarp-te-target-extent
# @title: GDAL gdalwarp -te target extent
# @description: Reprojects a synthetic EPSG:4326 raster to a sub-region with gdalwarp -te (xmin ymin xmax ymax) and verifies that gdalinfo -json reports corner coordinates clamped to the requested target extent.
# @timeout: 240
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalwarp-te-target-extent"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# Stamp the source raster with a known EPSG:4326 world-window from (-1,-1)..(1,1).
gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/src.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/src.tif"

# Warp to the inner half: -te xmin ymin xmax ymax = -0.5 -0.5 0.5 0.5.
gdalwarp -t_srs EPSG:4326 -te -0.5 -0.5 0.5 0.5 -tr 0.1 0.1 \
  "$tmpdir/src.tif" "$tmpdir/dst.tif" >"$tmpdir/warp.log" 2>&1
validator_require_file "$tmpdir/dst.tif"

gdalinfo -json "$tmpdir/dst.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (.cornerCoordinates.upperLeft[0]  | . > -0.5001 and . <  -0.4999)
  and (.cornerCoordinates.upperLeft[1]  | . >  0.4999 and . <   0.5001)
  and (.cornerCoordinates.lowerRight[0] | . >  0.4999 and . <   0.5001)
  and (.cornerCoordinates.lowerRight[1] | . > -0.5001 and . <  -0.4999)
' "$tmpdir/out.json"
