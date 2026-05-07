#!/usr/bin/env bash
# @testcase: usage-coreutils-r15-pr-omit-header-tflag
# @title: coreutils pr -t suppresses the header and trailer banner around input lines
# @description: Pipes a fixed three-line input through pr -t under LC_ALL=C, asserts the output equals the input exactly (no five-line top header, no five-line bottom blank trailer that pr emits by default) — exercising pr's libc-backed line buffering and header-suppression flag.
# @timeout: 60
# @tags: usage, coreutils, pr, r15
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'first\nsecond\nthird\n' >"$tmpdir/in.txt"

LC_ALL=C pr -t "$tmpdir/in.txt" >"$tmpdir/got.txt"

# With -t (omit header+trailer), output equals input byte-for-byte.
cmp "$tmpdir/got.txt" "$tmpdir/in.txt"
