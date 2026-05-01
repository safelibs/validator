#!/usr/bin/env bash
# @testcase: usage-gdal-gdaltransform-output-xy-only
# @title: GDAL gdaltransform -output_xy
# @description: Pipes a coordinate triple through gdaltransform -output_xy between EPSG:4326 and EPSG:3857 and verifies the output line carries exactly two whitespace-separated fields with the Z component dropped.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdaltransform-output-xy-only"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '0 0 100\n' | gdaltransform -s_srs EPSG:4326 -t_srs EPSG:3857 -output_xy >"$tmpdir/out.txt"
validator_require_file "$tmpdir/out.txt"

line=$(head -n1 "$tmpdir/out.txt")
fields=$(printf '%s\n' "$line" | awk '{print NF}')
[[ "$fields" == "2" ]] || {
  printf 'expected 2 fields, got %s: %s\n' "$fields" "$line" >&2
  exit 1
}

read -r x y <<<"$line"
[[ "$x" == "0" ]] || { printf 'expected easting 0, got %s\n' "$x" >&2; exit 1; }
[[ "$y" == "0" ]] || { printf 'expected northing 0, got %s\n' "$y" >&2; exit 1; }
