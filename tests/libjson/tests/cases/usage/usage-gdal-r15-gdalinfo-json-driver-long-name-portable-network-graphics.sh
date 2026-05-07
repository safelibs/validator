#!/usr/bin/env bash
# @testcase: usage-gdal-r15-gdalinfo-json-driver-long-name-portable-network-graphics
# @title: GDAL gdalinfo JSON .driverLongName equals "Portable Network Graphics" for a PNG
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted .driverLongName field equals the literal string "Portable Network Graphics", the documented PNG driver long name advertised by libgdal.
# @timeout: 180
# @tags: usage, gdal, json, driver
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '.driverLongName == "Portable Network Graphics"' "$tmpdir/out.json"
