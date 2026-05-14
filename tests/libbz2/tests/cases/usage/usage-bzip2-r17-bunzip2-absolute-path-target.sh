#!/usr/bin/env bash
# @testcase: usage-bzip2-r17-bunzip2-absolute-path-target
# @title: bunzip2 decompresses a target referenced by absolute path
# @description: Compresses a payload, moves the archive to a deeper subdirectory, then invokes bunzip2 with the absolute path to the archive and asserts the decompressed file appears alongside it stripped of the .bz2 suffix.
# @timeout: 60
# @tags: usage, bunzip2, absolute-path
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/a/b/c"
printf 'r17 absolute path target body\n' >"$tmpdir/a/b/c/file.txt"
bzip2 "$tmpdir/a/b/c/file.txt"
[[ -f "$tmpdir/a/b/c/file.txt.bz2" ]]

bunzip2 "$tmpdir/a/b/c/file.txt.bz2"

[[ -f "$tmpdir/a/b/c/file.txt" ]] || {
    printf 'expected decompressed file at absolute target path\n' >&2
    ls -la "$tmpdir/a/b/c" >&2
    exit 1
}
validator_assert_contains "$tmpdir/a/b/c/file.txt" 'r17 absolute path target body'
[[ ! -f "$tmpdir/a/b/c/file.txt.bz2" ]] || {
    printf 'archive should have been removed by default bunzip2\n' >&2
    exit 1
}
