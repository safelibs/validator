#!/usr/bin/env bash
# @testcase: usage-gio-r17-remove-then-list-omits-entry
# @title: gio remove deletes a regular file and gio list omits the entry afterwards
# @description: Creates a tmpdir file r17-victim.bin, removes it via gio remove, and asserts gio list of the parent directory does not contain the basename, exercising the unlink-then-list sequence to confirm post-removal directory state.
# @timeout: 60
# @tags: usage, gio, remove, list
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/r17-victim.bin"
gio list "$tmpdir" >"$tmpdir/before.txt"
validator_assert_contains "$tmpdir/before.txt" 'r17-victim.bin'

gio remove "$tmpdir/r17-victim.bin"
[[ ! -e "$tmpdir/r17-victim.bin" ]] || {
    printf 'expected file removed: %s/r17-victim.bin\n' "$tmpdir" >&2
    exit 1
}

gio list "$tmpdir" >"$tmpdir/after.txt"
if grep -Fq 'r17-victim.bin' "$tmpdir/after.txt"; then
    printf 'unexpectedly still listed:\n' >&2
    sed -n '1,40p' "$tmpdir/after.txt" >&2
    exit 1
fi
