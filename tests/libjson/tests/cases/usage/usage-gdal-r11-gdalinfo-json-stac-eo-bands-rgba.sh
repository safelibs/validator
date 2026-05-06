#!/usr/bin/env bash
# @testcase: usage-gdal-r11-gdalinfo-json-stac-eo-bands-rgba
# @title: GDAL gdalinfo JSON .stac.eo:bands names match RGBA description order
# @description: Runs gdalinfo -json against the bundled gdalicon RGBA PNG and verifies the json-c emitted .stac["eo:bands"] array contains exactly four entries named b1..b4 with descriptions Red, Green, Blue, Alpha in band order.
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
jq -e '
  (.stac["eo:bands"] | length == 4)
  and (.stac["eo:bands"][0].name == "b1") and (.stac["eo:bands"][0].description == "Red")
  and (.stac["eo:bands"][1].name == "b2") and (.stac["eo:bands"][1].description == "Green")
  and (.stac["eo:bands"][2].name == "b3") and (.stac["eo:bands"][2].description == "Blue")
  and (.stac["eo:bands"][3].name == "b4") and (.stac["eo:bands"][3].description == "Alpha")
' "$tmpdir/out.json"
