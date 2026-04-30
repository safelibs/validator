#!/usr/bin/env bash
# @testcase: usage-gdal-gdal-translate-mo-metadata
# @title: GDAL gdal_translate -mo custom metadata
# @description: Sets a custom dataset metadata key/value pair via gdal_translate -mo and verifies that gdalinfo -json echoes the entry in the default metadata domain.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdal-translate-mo-metadata"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

gdal_translate -of GTiff \
  -mo "VALIDATOR_KEY=validator-value" \
  "$raster" "$tmpdir/meta.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/meta.tif"

gdalinfo -json "$tmpdir/meta.tif" >"$tmpdir/out.json"
jq -e '
  .driverShortName == "GTiff"
  and (
    (.metadata // {})
    | (.[""] // .default // {})
    | (.VALIDATOR_KEY == "validator-value")
  )
' "$tmpdir/out.json"
