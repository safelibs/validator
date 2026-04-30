#!/usr/bin/env bash
# @testcase: usage-bunzip2-force-overwrite
# @title: bunzip2 force overwrite existing output
# @description: Pre-populates the decompressed output path with stale bytes and verifies bunzip2 -f replaces it with the recovered payload while keeping the compressed input via -k.
# @timeout: 180
# @tags: usage, bzip2, decompress
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bunzip2-force-overwrite"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'fresh decompress payload\n' >"$tmpdir/payload"
bzip2 -k "$tmpdir/payload"

# Replace the decompressed file with stale bytes that bunzip2 must overwrite.
printf 'stale bytes that must be replaced\n' >"$tmpdir/payload"

# Without -f bunzip2 must refuse to clobber the existing file.
set +e
bunzip2 -k "$tmpdir/payload.bz2" >"$tmpdir/refuse.out" 2>"$tmpdir/refuse.err"
rc=$?
set -e
if (( rc == 0 )); then
  printf 'bunzip2 unexpectedly clobbered existing output without -f\n' >&2
  exit 1
fi
grep -Fq 'payload' "$tmpdir/refuse.err"

# With -f bunzip2 must overwrite the existing output, and -k preserves the .bz2.
bunzip2 -kf "$tmpdir/payload.bz2"

[[ -f "$tmpdir/payload.bz2" ]]
validator_assert_contains "$tmpdir/payload" 'fresh decompress payload'
if grep -Fq 'stale bytes' "$tmpdir/payload"; then
  printf 'stale bytes survived bunzip2 -f overwrite\n' >&2
  exit 1
fi
