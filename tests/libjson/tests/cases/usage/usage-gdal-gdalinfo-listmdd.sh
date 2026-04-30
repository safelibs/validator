#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-listmdd
# @title: GDAL gdalinfo -listmdd lists metadata domains
# @description: Adds a custom IMAGE_STRUCTURE-related option and a default-domain -mo entry to a GTiff and verifies gdalinfo -listmdd is accepted and produces a Driver header alongside the listed domain set.
# @timeout: 180
# @tags: usage, gdal, raster
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalinfo-listmdd"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

raster=/usr/share/gdal/gdalicon.png
validator_require_file "$raster"

# A DEFLATE-compressed GTiff carries an IMAGE_STRUCTURE metadata domain in
# addition to the default one populated by -mo.
gdal_translate -of GTiff -co COMPRESS=DEFLATE \
  -mo "VALIDATOR_LISTMDD=present" \
  "$raster" "$tmpdir/listmdd.tif" >"$tmpdir/translate.log" 2>&1
validator_require_file "$tmpdir/listmdd.tif"

gdalinfo -listmdd "$tmpdir/listmdd.tif" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" 'Driver:'
# -listmdd renders a "Metadata domains:" section listing IMAGE_STRUCTURE
# (or similar) when present; the output must mention at least that label
# or a domain name. Accept either to remain stable across GDAL versions.
grep -Eq 'Metadata domains|IMAGE_STRUCTURE' "$tmpdir/info.txt" || {
  printf '-listmdd output did not list any metadata domain\n' >&2
  sed -n '1,80p' "$tmpdir/info.txt" >&2
  exit 1
}
