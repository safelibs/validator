#!/usr/bin/env bash
# @testcase: usage-findutils-r19-find-type-f-counts-files
# @title: find -type f counts only regular files and ignores directories and symlinks
# @description: Builds a tree of three regular files plus one subdirectory plus one symlink, runs find -type f piped to wc -l, and asserts the count equals exactly 3 - locking in libc-backed lstat handling that distinguishes regular files from other inode kinds.
# @timeout: 30
# @tags: usage, findutils, type-f, r19
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/root/sub"
: >"$tmpdir/root/a"
: >"$tmpdir/root/b"
: >"$tmpdir/root/sub/c"
ln -s "$tmpdir/root/a" "$tmpdir/root/link"

n=$(find "$tmpdir/root" -type f | wc -l)
[[ "$n" -eq 3 ]] || {
    printf 'expected 3, got %s\n' "$n" >&2
    find "$tmpdir/root" -type f >&2
    exit 1
}
