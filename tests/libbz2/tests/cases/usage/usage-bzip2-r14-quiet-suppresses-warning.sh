#!/usr/bin/env bash
# @testcase: usage-bzip2-r14-quiet-suppresses-warning
# @title: bzip2 -q quiets warnings on a non-canonical-suffix output decode
# @description: Decompresses a .bz2 stream from a file whose extension is not .bz2 (so bzip2 normally complains) using "bzip2 -d -q -c", asserts the command exits zero with empty stderr, and that stdout matches the original payload sha256 — confirming -q silences the suffix-related warning chatter without affecting decode correctness.
# @timeout: 60
# @tags: usage, bzip2, quiet
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'quiet payload alpha beta\n' >"$tmpdir/in.txt"
src_sha=$(sha256sum "$tmpdir/in.txt" | awk '{print $1}')

bzip2 -c "$tmpdir/in.txt" >"$tmpdir/blob.dat"

bzip2 -d -q -c "$tmpdir/blob.dat" >"$tmpdir/out.txt" 2>"$tmpdir/err.log"

[[ ! -s "$tmpdir/err.log" ]] || {
    printf 'expected empty stderr with -q; got:\n' >&2
    cat "$tmpdir/err.log" >&2
    exit 1
}

out_sha=$(sha256sum "$tmpdir/out.txt" | awk '{print $1}')
test "$src_sha" = "$out_sha"
