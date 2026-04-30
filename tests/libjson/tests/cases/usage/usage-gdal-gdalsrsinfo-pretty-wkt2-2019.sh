#!/usr/bin/env bash
# @testcase: usage-gdal-gdalsrsinfo-pretty-wkt2-2019
# @title: GDAL gdalsrsinfo pretty WKT2 2019
# @description: Renders EPSG:4326 with gdalsrsinfo -o wkt2_2019 in pretty (multi-line) form and verifies the output spans multiple indented lines while still carrying the GEOGCRS root keyword.
# @timeout: 180
# @tags: usage, gdal, srs
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalsrsinfo-pretty-wkt2-2019"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdalsrsinfo -o wkt2_2019 -p EPSG:4326 >"$tmpdir/pretty.wkt"
validator_require_file "$tmpdir/pretty.wkt"
validator_assert_contains "$tmpdir/pretty.wkt" 'GEOGCRS'
validator_assert_contains "$tmpdir/pretty.wkt" 'WGS 84'

# Pretty output must span multiple lines (ordinary -o wkt2_2019 returns a single
# long line). Require at least 5 newline-separated lines.
lines=$(wc -l <"$tmpdir/pretty.wkt")
if (( lines < 5 )); then
  printf 'expected pretty WKT2 to span >=5 lines, got %s\n' "$lines" >&2
  cat "$tmpdir/pretty.wkt" >&2
  exit 1
fi
