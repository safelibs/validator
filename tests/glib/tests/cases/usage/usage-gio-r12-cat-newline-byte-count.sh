#!/usr/bin/env bash
# @testcase: usage-gio-r12-cat-newline-byte-count
# @title: gio cat preserves trailing newline byte count
# @description: Writes a 4-line UTF-8 text file (12 bytes including trailing newlines), runs gio cat, and asserts the captured output has exactly the same byte count as the source.
# @timeout: 60
# @tags: usage, gio, cat
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a\nb\nc\nd\n' >"$tmpdir/in.txt"
expected=$(wc -c <"$tmpdir/in.txt")

gio cat "$tmpdir/in.txt" >"$tmpdir/out"
got=$(wc -c <"$tmpdir/out")
[[ "$got" = "$expected" ]] || { echo "size mismatch: $got vs $expected" >&2; exit 1; }
cmp "$tmpdir/in.txt" "$tmpdir/out"
