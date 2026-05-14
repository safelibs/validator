#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-test-flag-valid-rc-zero
# @title: bzip2 -t on a valid archive exits zero and leaves no payload on stdout
# @description: Compresses a small text file to bzip2, runs bzip2 -t against the archive capturing stdout, and asserts the command exits with status zero and writes zero bytes to stdout — locking in the integrity-check command being silent on stdout for healthy archives.
# @timeout: 30
# @tags: usage, bzip2, test, integrity, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'hello world\n' >"$tmpdir/p.txt"
bzip2 -k "$tmpdir/p.txt"

bzip2 -t "$tmpdir/p.txt.bz2" >"$tmpdir/out"
rc=$?
[[ "$rc" -eq 0 ]] || { printf 'expected rc=0 from bzip2 -t, got %s\n' "$rc" >&2; exit 1; }

bytes=$(wc -c <"$tmpdir/out")
[[ "$bytes" -eq 0 ]] || {
    printf 'expected zero-byte stdout, got %s\n' "$bytes" >&2
    cat "$tmpdir/out" >&2
    exit 1
}
