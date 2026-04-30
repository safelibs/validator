#!/usr/bin/env bash
# @testcase: usage-gdal-gdalmanage-identify-gtiff
# @title: GDAL gdalmanage identify on a GTiff
# @description: Builds a GTiff from the bundled gdalicon raster and runs gdalmanage identify on it, verifying that the GTiff driver is named in the textual output.
# @timeout: 180
# @tags: usage, gdal, raster
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalmanage-identify-gtiff"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff "$raster" "$tmpdir/icon.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/icon.tif"

gdalmanage identify "$tmpdir/icon.tif" >"$tmpdir/identify.txt" 2>&1
validator_require_file "$tmpdir/identify.txt"
validator_assert_contains "$tmpdir/identify.txt" 'icon.tif'
validator_assert_contains "$tmpdir/identify.txt" 'GTiff'
