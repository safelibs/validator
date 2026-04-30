#!/usr/bin/env bash
# @testcase: usage-gdal-gdalsrsinfo-validate-invalid
# @title: GDAL gdalsrsinfo -V rejects an invalid SRS string
# @description: Runs gdalsrsinfo -V against a clearly invalid SRS definition and verifies the tool exits non-zero, treating the validate flag as a real validation step rather than a no-op.
# @timeout: 180
# @tags: usage, gdal, raster
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalsrsinfo-validate-invalid"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# A nonsense WKT-shaped string that is not a real coordinate reference
# system. gdalsrsinfo -V must refuse to validate it.
bad_srs='GARBAGE["not-a-real-srs",FOO[BAR]]'

set +e
gdalsrsinfo -V "$bad_srs" >"$tmpdir/out.txt" 2>&1
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
  printf 'gdalsrsinfo -V unexpectedly accepted invalid SRS (exit 0)\n' >&2
  sed -n '1,80p' "$tmpdir/out.txt" >&2
  exit 1
fi
