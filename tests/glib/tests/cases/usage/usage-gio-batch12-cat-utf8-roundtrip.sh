#!/usr/bin/env bash
# @testcase: usage-gio-batch12-cat-utf8-roundtrip
# @title: gio cat preserves UTF-8 multi-byte content
# @description: Writes a UTF-8 file with non-ASCII characters and verifies gio cat reads back the exact same bytes.
# @timeout: 60
# @tags: usage, gio, utf8
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'caf\xc3\xa9 \xe2\x98\x83 \xf0\x9f\x90\x8d\n' >"$tmpdir/in.txt"
gio cat "$tmpdir/in.txt" >"$tmpdir/out.txt"
cmp "$tmpdir/in.txt" "$tmpdir/out.txt"
