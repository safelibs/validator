#!/usr/bin/env bash
# @testcase: usage-gdalsrsinfo-nad83-datum
# @title: GDAL gdalsrsinfo NAD83 datum name
# @description: Renders EPSG:4269 (NAD83) with gdalsrsinfo -o wkt and verifies the WKT mentions the North American Datum 1983 (the canonical PROJ datum name) and the GEOGCRS root keyword.
# @timeout: 180
# @tags: usage, gdal, srs
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdalsrsinfo-nad83-datum"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# WKT form should report GEOGCRS for a 2D geographic CRS plus the NAD83 name.
gdalsrsinfo -o wkt EPSG:4269 >"$tmpdir/wkt.txt"
validator_require_file "$tmpdir/wkt.txt"
validator_assert_contains "$tmpdir/wkt.txt" 'GEOGCRS'
grep -Eq 'NAD83|North American Datum 1983' "$tmpdir/wkt.txt" || {
  printf 'expected NAD83 datum reference in WKT, got:\n' >&2
  sed -n '1,40p' "$tmpdir/wkt.txt" >&2
  exit 1
}

# Cross-check via PROJJSON: the document must validate as JSON, name the
# CRS "NAD83", and reference EPSG:4269 somewhere in the body.
gdalsrsinfo -o projjson EPSG:4269 >"$tmpdir/proj.json"
jq -e 'type == "object"' "$tmpdir/proj.json" >/dev/null
grep -Fq 'NAD83' "$tmpdir/proj.json" || {
  printf 'expected NAD83 in projjson body\n' >&2
  cat "$tmpdir/proj.json" >&2
  exit 1
}
grep -Fq '"EPSG"' "$tmpdir/proj.json" || {
  printf 'expected EPSG authority in projjson body\n' >&2
  cat "$tmpdir/proj.json" >&2
  exit 1
}
grep -Eq '"code"[[:space:]]*:[[:space:]]*"?4269"?' "$tmpdir/proj.json" || {
  printf 'expected code 4269 in projjson body\n' >&2
  cat "$tmpdir/proj.json" >&2
  exit 1
}
