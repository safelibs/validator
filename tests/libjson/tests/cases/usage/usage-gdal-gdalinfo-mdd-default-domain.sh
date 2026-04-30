#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-mdd-default-domain
# @title: GDAL gdalinfo -mdd default metadata domain
# @description: Stamps a custom -mo metadata pair onto a GTiff via gdal_translate, then asks gdalinfo -mdd default for that domain and verifies the value is rendered in the textual report.
# @timeout: 180
# @tags: usage, gdal, raster
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-mdd-default-domain"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff \
  -mo "VALIDATOR_DOMAIN_KEY=validator-default" \
  "$raster" "$tmpdir/mdd.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/mdd.tif"

gdalinfo -mdd default "$tmpdir/mdd.tif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Driver:'
validator_assert_contains "$tmpdir/info.txt" 'VALIDATOR_DOMAIN_KEY=validator-default'
