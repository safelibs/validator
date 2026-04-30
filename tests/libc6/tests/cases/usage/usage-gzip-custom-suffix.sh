#!/usr/bin/env bash
# @testcase: usage-gzip-custom-suffix
# @title: gzip custom suffix roundtrip
# @description: Compresses a file using gzip -S with a non-default suffix and verifies decompression restores the original payload.
# @timeout: 180
# @tags: usage, gzip, archive
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gzip-custom-suffix"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'custom-suffix payload\n' >"$tmpdir/file.dat"
gzip -S .gzcustom "$tmpdir/file.dat"

if [[ ! -f "$tmpdir/file.dat.gzcustom" ]]; then
  printf 'expected file.dat.gzcustom to exist after gzip -S\n' >&2
  ls -la "$tmpdir" >&2
  exit 1
fi
if [[ -f "$tmpdir/file.dat" ]]; then
  printf 'original file.dat should have been replaced by gzip\n' >&2
  exit 1
fi

gzip -d -S .gzcustom "$tmpdir/file.dat.gzcustom"
validator_assert_contains "$tmpdir/file.dat" 'custom-suffix payload'
