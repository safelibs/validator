#!/usr/bin/env bash
# @testcase: usage-bzip2-r16-k-flag-keeps-original
# @title: bzip2 -k keeps the input file alongside the compressed output
# @description: Compresses a file with bzip2 -k and asserts both the original input and the .bz2 output exist afterwards, locking in the keep-input flag behavior that distinguishes -k from the default "consume the input" path.
# @timeout: 60
# @tags: usage, bzip2, keep, flag
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r16 keep-flag payload line one\nline two\n' >"$tmpdir/payload.txt"
sha_before=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')

bzip2 -k "$tmpdir/payload.txt"

validator_require_file "$tmpdir/payload.txt"
validator_require_file "$tmpdir/payload.txt.bz2"

sha_after=$(sha256sum "$tmpdir/payload.txt" | awk '{print $1}')
test "$sha_before" = "$sha_after"

bunzip2 -c "$tmpdir/payload.txt.bz2" >"$tmpdir/roundtrip.txt"
diff -q "$tmpdir/payload.txt" "$tmpdir/roundtrip.txt"
