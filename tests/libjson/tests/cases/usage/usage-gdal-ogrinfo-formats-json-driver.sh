#!/usr/bin/env bash
# @testcase: usage-gdal-ogrinfo-formats-json-driver
# @title: GDAL ogrinfo --formats GeoJSON driver
# @description: Runs ogrinfo --formats and verifies the GeoJSON, GeoJSONSeq and ESRIJSON vector drivers are advertised as read-capable in the listing.
# @timeout: 120
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogrinfo-formats-json-driver"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ogrinfo --formats >"$tmpdir/formats.txt" 2>&1
validator_require_file "$tmpdir/formats.txt"
grep -Eq '^[[:space:]]*GeoJSON[[:space:]]+-vector-' "$tmpdir/formats.txt" || {
  printf 'GeoJSON driver not listed by ogrinfo --formats\n' >&2
  sed -n '1,160p' "$tmpdir/formats.txt" >&2
  exit 1
}
grep -Eq '^[[:space:]]*GeoJSONSeq[[:space:]]+-vector-' "$tmpdir/formats.txt" || {
  printf 'GeoJSONSeq driver not listed by ogrinfo --formats\n' >&2
  sed -n '1,160p' "$tmpdir/formats.txt" >&2
  exit 1
}
grep -Eq '^[[:space:]]*ESRIJSON[[:space:]]+-vector-' "$tmpdir/formats.txt" || {
  printf 'ESRIJSON driver not listed by ogrinfo --formats\n' >&2
  sed -n '1,160p' "$tmpdir/formats.txt" >&2
  exit 1
}
