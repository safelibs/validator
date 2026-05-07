#!/usr/bin/env bash
# @testcase: usage-gdal-r14-gdalinfo-json-description-matches-path
# @title: GDAL gdalinfo JSON .description equals the dataset path
# @description: Runs gdalinfo -json on the bundled gdalicon PNG copied into a tempdir and verifies the json-c emitted .description field equals the exact filesystem path passed on the command line, confirming the documented dataset description encoding.
# @timeout: 180
# @tags: usage, gdal, json, description
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e --arg p "$tmpdir/icon.png" '.description == $p' "$tmpdir/out.json"
