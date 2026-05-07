#!/usr/bin/env bash
# @testcase: usage-gdal-r15-gdalinfo-json-bands-metadata-empty-object
# @title: GDAL gdalinfo JSON .bands[0].metadata is an empty object on the bundled icon
# @description: Runs gdalinfo -json on the bundled gdalicon PNG and verifies the json-c emitted .bands[0].metadata is an object with zero keys, the documented metadata default when no per-band metadata is set.
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
  (.bands[0].metadata | type == "object")
  and ((.bands[0].metadata | keys | length) == 0)
' "$tmpdir/out.json"
