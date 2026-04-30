#!/usr/bin/env bash
# @testcase: usage-gdal-gdaltransform-epsg-roundtrip
# @title: GDAL gdaltransform EPSG roundtrip
# @description: Pipes a coordinate pair through gdaltransform between EPSG:4326 and EPSG:3857 and verifies the projected easting matches the expected webmercator value.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdaltransform-epsg-roundtrip"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '0 0\n' | gdaltransform -s_srs EPSG:4326 -t_srs EPSG:3857 >"$tmpdir/out.txt"
validator_require_file "$tmpdir/out.txt"
read -r x y _ <"$tmpdir/out.txt"
[[ "$x" == "0" ]] || { printf 'expected easting 0, got %s\n' "$x" >&2; cat "$tmpdir/out.txt" >&2; exit 1; }
[[ "$y" == "0" ]] || { printf 'expected northing 0, got %s\n' "$y" >&2; cat "$tmpdir/out.txt" >&2; exit 1; }
