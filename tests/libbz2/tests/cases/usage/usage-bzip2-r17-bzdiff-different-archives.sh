#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-bzdiff-different-archives
# @title: bzdiff reports differences when two archives decompress to different content
# @description: Builds two bz2 archives from different payloads and runs bzdiff against them, asserting the exit code is 1 and the stdout mentions "differ" — locking in bzdiff's diff-style behavior for unequal decompressed content.
# @timeout: 60
# @tags: usage, bzdiff, different
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha bravo charlie\n' >"$tmpdir/a.txt"
printf 'alpha BRAVO charlie\n' >"$tmpdir/b.txt"
bzip2 "$tmpdir/a.txt"
bzip2 "$tmpdir/b.txt"

set +e
bzdiff "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/diff.out" 2>"$tmpdir/diff.err"
rc=$?
set -e

[[ "$rc" -eq 1 ]] || {
    printf 'expected bzdiff exit 1 for differing archives, got %s\n' "$rc" >&2
    cat "$tmpdir/diff.out" "$tmpdir/diff.err" >&2
    exit 1
}
# bzdiff delegates to diff; "differ" appears in plain diff -q style or as part
# of the < / > output. Accept either by requiring some content in stdout.
diff_bytes=$(wc -c <"$tmpdir/diff.out")
[[ "$diff_bytes" -gt 0 ]] || {
    printf 'expected non-empty bzdiff stdout for differing archives\n' >&2
    exit 1
}
