#!/usr/bin/env bash
# @testcase: usage-gio-r18-rename-target-content-equals-source-content
# @title: gio rename keeps the payload bytes identical between original and renamed file
# @description: Writes a 16-byte deterministic payload to a tmpdir source file, runs gio rename to give it a new basename in the same directory, and asserts gio cat on the renamed file produces the exact original byte sequence, exercising the rename operation as a content-preservation check distinct from listing-based rename tests.
# @timeout: 60
# @tags: usage, gio, rename, content-preserved, r18
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

src="$tmpdir/before.txt"
printf 'r18-rename-payload\n' >"$src"
expected=$(cat "$src")

gio rename "$src" 'after.txt'
gio cat "$tmpdir/after.txt" >"$tmpdir/out.txt"
got=$(cat "$tmpdir/out.txt")
[[ "$got" == "$expected" ]] || {
    printf 'mismatch expected=%q got=%q\n' "$expected" "$got" >&2
    exit 1
}
