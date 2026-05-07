#!/usr/bin/env bash
# @testcase: usage-gdal-r13-gdalinfo-json-stac-proj-shape-32x32
# @title: GDAL gdalinfo JSON .stac["proj:shape"] equals [32, 32] for the bundled icon
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted .stac["proj:shape"] array equals [32, 32], the documented STAC representation of the icon's pixel-space height x width.
# @timeout: 180
# @tags: usage, gdal, json, stac
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '.stac["proj:shape"] == [32, 32]' "$tmpdir/out.json"
