#!/usr/bin/env bash
# @testcase: usage-gdal-r13-gdalinfo-json-image-structure-compression-lzw
# @title: GDAL gdalinfo JSON metadata.IMAGE_STRUCTURE.COMPRESSION is "LZW" for an LZW GTiff
# @description: Translates the bundled gdalicon PNG to a GeoTIFF with -co COMPRESS=LZW and verifies gdalinfo -json (json-c serialised) reports metadata.IMAGE_STRUCTURE.COMPRESSION exactly equal to the string "LZW", confirming the creation option round-trips through the structural metadata.
# @timeout: 180
# @tags: usage, gdal, json, metadata
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff -co COMPRESS=LZW \
  "$raster" "$tmpdir/out.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/out.tif"

gdalinfo -json "$tmpdir/out.tif" >"$tmpdir/out.json"
jq -e '.metadata.IMAGE_STRUCTURE.COMPRESSION == "LZW"' "$tmpdir/out.json"
