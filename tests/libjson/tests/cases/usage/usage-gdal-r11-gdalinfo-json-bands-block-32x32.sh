#!/usr/bin/env bash
# @testcase: usage-gdal-r11-gdalinfo-json-bands-block-32x32
# @title: GDAL gdalinfo JSON every band reports a 32x32 block dimension
# @description: Runs gdalinfo -json on the bundled gdalicon 32x32 PNG and verifies the json-c emitted .bands[].block array equals [32, 32] for every band, exposing PNG's whole-image strip layout uniformly across channels.
# @timeout: 180
# @tags: usage, gdal, json, bands
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"
cp "$raster" "$tmpdir/icon.png"

gdalinfo -json "$tmpdir/icon.png" >"$tmpdir/out.json"
jq -e '
  (.bands | length == 4)
  and (.bands | all(.block == [32, 32]))
' "$tmpdir/out.json"
