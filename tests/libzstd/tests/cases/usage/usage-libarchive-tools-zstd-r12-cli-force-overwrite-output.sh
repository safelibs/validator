#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-zstd-r12-cli-force-overwrite-output
# @title: zstd -f overwrites an existing destination file silently
# @description: Pre-creates a destination file containing a sentinel string, runs zstd -f to encode a fresh payload to that path, and asserts the destination is replaced by a real zstd frame whose decode matches the source.
# @timeout: 60
# @tags: usage, zstd, cli, force
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r12 force payload row\n%.0s' {1..300} >"$tmpdir/in.txt"
printf 'PRE-EXISTING-SENTINEL\n' >"$tmpdir/in.txt.zst"

# Without -f, zstd refuses to clobber the existing file.
set +e
zstd -q "$tmpdir/in.txt" -o "$tmpdir/in.txt.zst" </dev/null >/dev/null 2>"$tmpdir/err1"
ec=$?
set -e
[[ $ec -ne 0 ]] || {
    printf 'expected zstd to refuse overwrite without -f\n' >&2
    exit 1
}

# With -f, the existing target is replaced by a real zstd frame.
zstd -f -q "$tmpdir/in.txt" -o "$tmpdir/in.txt.zst"

magic=$(od -An -N4 -tx1 "$tmpdir/in.txt.zst" | tr -d ' \n')
[[ "$magic" == "28b52ffd" ]] || {
    printf 'expected zstd magic 28b52ffd, got %s\n' "$magic" >&2
    exit 1
}

zstd -dq "$tmpdir/in.txt.zst" -o "$tmpdir/decoded.txt"
cmp "$tmpdir/decoded.txt" "$tmpdir/in.txt"
