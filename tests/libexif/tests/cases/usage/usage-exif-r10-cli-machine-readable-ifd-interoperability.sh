#!/usr/bin/env bash
# @testcase: usage-exif-r10-cli-machine-readable-ifd-interoperability
# @title: exif --machine-readable --ifd=Interoperability dumps the interop entries
# @description: Runs exif --machine-readable --ifd=Interoperability against the canon fixture and verifies the dump contains the Interoperability Index R98, Interoperability Version 0100, RelatedImageWidth 640, and RelatedImageLength 480 entries libexif exposes from that IFD as tab-delimited rows.
# @timeout: 60
# @tags: usage, metadata, ifd
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

img="$VALIDATOR_SAMPLE_ROOT/test/testdata/canon_makernote_variant_1.jpg"
validator_require_file "$img"

exif --machine-readable --ifd=Interoperability "$img" >"$tmpdir/out"

# Tab-separated key/value rows for the canonical interop entries
expected_idx=$(printf 'Interoperability Index\tR98\n')
if ! grep -Fq -- "$expected_idx" "$tmpdir/out"; then
  printf 'expected Interoperability Index<TAB>R98 row\n' >&2
  od -An -c "$tmpdir/out" | head >&2
  exit 1
fi

expected_ver=$(printf 'Interoperability Version\t0100\n')
if ! grep -Fq -- "$expected_ver" "$tmpdir/out"; then
  printf 'expected Interoperability Version<TAB>0100 row\n' >&2
  od -An -c "$tmpdir/out" | head >&2
  exit 1
fi

expected_w=$(printf 'RelatedImageWidth\t640\n')
expected_l=$(printf 'RelatedImageLength\t480\n')
grep -Fq -- "$expected_w" "$tmpdir/out"
grep -Fq -- "$expected_l" "$tmpdir/out"

# The pretty pipe-table separator must not appear in machine-readable output
if grep -Fq -- '|' "$tmpdir/out"; then
  printf 'machine-readable interop dump unexpectedly contained a pipe character\n' >&2
  cat "$tmpdir/out" >&2
  exit 1
fi
