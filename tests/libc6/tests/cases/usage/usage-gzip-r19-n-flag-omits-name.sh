#!/usr/bin/env bash
# @testcase: usage-gzip-r19-n-flag-omits-name
# @title: gzip -n strips the original filename from the gzip header
# @description: Compresses a named file twice (once with default options, once with -n -c), inspects the gzip header byte at offset 3 of both archives via od, and asserts the -n archive has the FNAME bit (0x08) clear while the default archive has it set - locking in libc-backed header field control via the gzip -n flag.
# @timeout: 30
# @tags: usage, gzip, header, fname, r19
# @client: gzip

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'gzip-header-fname-test\n' >"$tmpdir/payload.txt"

# Default: header should include FNAME (0x08 bit set in byte 3).
gzip -c "$tmpdir/payload.txt" >"$tmpdir/with.gz"
# -n: should strip name (FNAME bit clear).
gzip -nc "$tmpdir/payload.txt" >"$tmpdir/without.gz"

flags_with=$(od -An -j3 -N1 -tx1 "$tmpdir/with.gz" | tr -d ' \n')
flags_without=$(od -An -j3 -N1 -tx1 "$tmpdir/without.gz" | tr -d ' \n')

with_bit=$(( 0x${flags_with} & 0x08 ))
without_bit=$(( 0x${flags_without} & 0x08 ))

[[ "$with_bit" -eq 8 ]] || {
    printf 'expected default gzip to set FNAME bit, flags=%s\n' "$flags_with" >&2
    exit 1
}
[[ "$without_bit" -eq 0 ]] || {
    printf 'expected -n to clear FNAME bit, flags=%s\n' "$flags_without" >&2
    exit 1
}
