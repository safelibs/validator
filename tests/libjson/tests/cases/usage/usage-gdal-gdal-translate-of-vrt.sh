#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-of-vrt
# @title: GDAL gdal_translate VRT output
# @description: Wraps a small GeoTIFF in a VRT side-car via gdal_translate -of VRT and verifies gdalinfo -json on the VRT reports the VRT driver and a SourceFilename pointing at the underlying TIFF.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-of-vrt"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -a_srs EPSG:4326 -a_ullr -1 1 1 -1 \
  "$raster" "$tmpdir/src.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/src.tif"

gdal_translate -of VRT "$tmpdir/src.tif" "$tmpdir/wrap.vrt" >"$tmpdir/vrt.log" 2>&1
validator_require_file "$tmpdir/wrap.vrt"
validator_assert_contains "$tmpdir/wrap.vrt" '<VRTDataset'
validator_assert_contains "$tmpdir/wrap.vrt" 'src.tif'

gdalinfo -json "$tmpdir/wrap.vrt" >"$tmpdir/out.json"
jq -e '.driverShortName == "VRT" and (.size | length) == 2' "$tmpdir/out.json"
