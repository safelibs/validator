#!/usr/bin/env bash
# @testcase: usage-gio-r10-cat-empty-file
# @title: gio cat on empty file produces zero bytes
# @description: Creates a zero-length file and verifies gio cat produces an empty output (zero bytes) and exits cleanly.
# @timeout: 60
# @tags: usage, gio, cat
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.bin"
gio cat "$tmpdir/empty.bin" >"$tmpdir/out.bin"
size=$(stat -c '%s' "$tmpdir/out.bin")
[[ "$size" == 0 ]]
