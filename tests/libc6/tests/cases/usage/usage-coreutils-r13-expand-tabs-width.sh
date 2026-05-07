#!/usr/bin/env bash
# @testcase: usage-coreutils-r13-expand-tabs-width
# @title: coreutils expand -t 4 substitutes tabs with 4-space stops via libc I/O
# @description: Pipes a tab-delimited record through expand -t 4 under LC_ALL=C and asserts each tab is converted to padded spaces such that columns align on the next 4-column stop.
# @timeout: 60
# @tags: usage, coreutils, expand
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a\tb\tc\n' >"$tmpdir/in.txt"
LC_ALL=C expand -t 4 "$tmpdir/in.txt" >"$tmpdir/got.txt"
got=$(cat "$tmpdir/got.txt")
# 'a' at col 0, tab fills to col 4 (3 spaces), 'b' at col 4, tab fills to col 8 (3 spaces), 'c' at col 8.
[[ "$got" == "a   b   c" ]]
