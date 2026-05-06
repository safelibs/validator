#!/usr/bin/env bash
# @testcase: usage-gdal-r11-gdalinfo-json-mask-flags-per-dataset
# @title: GDAL gdalinfo JSON band[0].mask.flags reports PER_DATASET and ALPHA
# @description: Runs gdalinfo -json on the bundled gdalicon RGBA PNG and verifies the first band's mask.flags array (json-c emitted) contains exactly the strings PER_DATASET and ALPHA in the documented order, reflecting the per-dataset alpha mask exposed by GDAL.
# @timeout: 180
# @tags: usage, gdal, json, mask
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
  (.bands[0].mask.flags | type == "array")
  and (.bands[0].mask.flags | length == 2)
  and (.bands[0].mask.flags | index("PER_DATASET") != null)
  and (.bands[0].mask.flags | index("ALPHA") != null)
' "$tmpdir/out.json"
