#!/usr/bin/env bash
# @testcase: usage-gdal-gdaltransform-output-xy-bounds
# @title: GDAL gdaltransform projects bbox corner within expected bounds
# @description: Pipes a known WGS84 lon/lat pair (90 deg east, 0 deg north) through gdaltransform to EPSG:3857 and asserts the projected easting falls inside an explicit numeric bounding box that brackets the canonical webmercator value.
# @timeout: 180
# @tags: usage, gdal, raster
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdaltransform-output-xy-bounds"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# 90 deg East, 0 deg North in EPSG:3857 is a quarter of the equator
# circumference in meters: roughly 1.0018e7. We bracket it with an
# explicit bbox of 1.00e7 .. 1.01e7 on x and -1.0 .. 1.0 on y.
printf '90 0\n' | gdaltransform -s_srs EPSG:4326 -t_srs EPSG:3857 \
  >"$tmpdir/out.txt"
validator_require_file "$tmpdir/out.txt"

read -r x y _ <"$tmpdir/out.txt"

awk -v x="$x" -v y="$y" '
  BEGIN {
    if (x+0 < 1.00e7 || x+0 > 1.01e7) {
      printf "easting %s outside bbox [1.00e7, 1.01e7]\n", x > "/dev/stderr"
      exit 1
    }
    if (y+0 < -1.0 || y+0 > 1.0) {
      printf "northing %s outside bbox [-1.0, 1.0]\n", y > "/dev/stderr"
      exit 1
    }
  }
'
