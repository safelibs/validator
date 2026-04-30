#!/usr/bin/env bash
# @testcase: usage-exif-cli-no-exif-error
# @title: exif rejects JPEG without EXIF data
# @description: Synthesises a minimal JFIF JPEG with no EXIF segment, runs the exif client against it, and verifies the client exits non-zero and prints the does not contain EXIF data diagnostic naming the synthesised file.
# @timeout: 60
# @tags: usage, metadata
# @client: exif

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-exif-cli-no-exif-error"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

plain="$tmpdir/plain.jpg"

# Minimal JFIF JPEG: SOI + APP0 JFIF + a small DQT + EOI.
{
  printf '\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00'
  printf '\xff\xdb\x00\x43\x00'
  # 64 bytes of dummy quantisation table content
  python3 -c "import sys; sys.stdout.buffer.write(bytes(range(1, 65)))"
  printf '\xff\xd9'
} >"$plain"

validator_require_file "$plain"

set +e
exif "$plain" >"$tmpdir/stdout" 2>"$tmpdir/stderr"
rc=$?
set -e

if (( rc == 0 )); then
  printf 'expected exif to fail on JPEG without EXIF, got rc=0\n' >&2
  cat "$tmpdir/stdout" "$tmpdir/stderr" >&2
  exit 1
fi

cat "$tmpdir/stdout" "$tmpdir/stderr" >"$tmpdir/all"
validator_assert_contains "$tmpdir/all" 'does not contain EXIF data'
validator_assert_contains "$tmpdir/all" 'plain.jpg'
