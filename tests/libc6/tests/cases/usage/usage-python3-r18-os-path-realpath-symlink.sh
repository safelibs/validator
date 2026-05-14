#!/usr/bin/env bash
# @testcase: usage-python3-r18-os-path-realpath-symlink
# @title: python3 os.path.realpath resolves a symlink to its target via libc
# @description: Creates a target file and a symlink pointing at it, then invokes python3 -c with os.path.realpath against the symlink and asserts the resolved path matches the realpath of the target file — locking in libc-backed readlink chain resolution.
# @timeout: 30
# @tags: usage, python3, realpath, symlink, r18
# @client: python3

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

touch "$tmpdir/target.txt"
ln -s "$tmpdir/target.txt" "$tmpdir/link.txt"

want=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$tmpdir/target.txt")
got=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$tmpdir/link.txt")

[[ "$got" == "$want" ]] || {
    printf 'realpath mismatch: want=%s got=%s\n' "$want" "$got" >&2
    exit 1
}
