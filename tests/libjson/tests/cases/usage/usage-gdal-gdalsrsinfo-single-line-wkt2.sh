#!/usr/bin/env bash
# @testcase: usage-gdal-gdalsrsinfo-single-line-wkt2
# @title: GDAL gdalsrsinfo --single-line WKT2 output
# @description: Runs gdalsrsinfo --single-line -o wkt2_2019 EPSG:4326 and verifies the WKT is emitted on a single line beginning with the GEOGCRS keyword and embedding the EPSG:4326 authority id.
# @timeout: 120
# @tags: usage, gdal, srs
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalsrsinfo-single-line-wkt2"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdalsrsinfo --single-line -o wkt2_2019 EPSG:4326 >"$tmpdir/out.wkt"
validator_require_file "$tmpdir/out.wkt"

# Strip blank lines, then expect exactly one non-empty line that starts with
# GEOGCRS[ and references the EPSG:4326 authority id.
nonblank=$(grep -c '[^[:space:]]' "$tmpdir/out.wkt" || true)
if [[ "$nonblank" != "1" ]]; then
  printf 'expected single-line WKT2, got %s non-blank lines\n' "$nonblank" >&2
  cat "$tmpdir/out.wkt" >&2
  exit 1
fi

grep -q '^GEOGCRS\[' "$tmpdir/out.wkt"
validator_assert_contains "$tmpdir/out.wkt" 'ID["EPSG",4326]'
