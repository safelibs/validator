#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzcmp-identical-archives-rc-zero
# @title: bzcmp returns rc 0 and empty stdout on two archives compressed from the same source
# @description: Writes a source payload, compresses it into two distinct archive files at the same level, then runs bzcmp on the two archives and asserts rc 0 with empty stdout since the underlying decompressed bytes are identical, exercising bzcmp's content-equality semantics on identical compressed inputs distinct from prior different-exit tests.
# @timeout: 30
# @tags: usage, bzcmp, identical, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r20 bzcmp identical payload\nline two\n' >"$tmpdir/src.txt"

bzip2 -c "$tmpdir/src.txt" >"$tmpdir/a.bz2"
bzip2 -c "$tmpdir/src.txt" >"$tmpdir/b.bz2"

bzcmp "$tmpdir/a.bz2" "$tmpdir/b.bz2" >"$tmpdir/out.txt" 2>&1
[[ ! -s "$tmpdir/out.txt" ]] || {
    printf 'expected empty stdout, got:\n' >&2
    cat "$tmpdir/out.txt" >&2
    exit 1
}
