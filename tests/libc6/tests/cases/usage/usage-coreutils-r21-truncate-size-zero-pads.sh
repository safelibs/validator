#!/usr/bin/env bash
# @testcase: usage-coreutils-r21-truncate-size-zero-pads
# @title: truncate -s 1024 grows a tiny file to exactly 1024 bytes
# @description: Writes a 4-byte file then runs truncate -s 1024 against it, asserting the resulting file size is exactly 1024 bytes - locking in the size-extension code path of truncate which is not covered by existing coreutils tests.
# @timeout: 30
# @tags: usage, coreutils, truncate, r21
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'abcd' >"$tmpdir/f.bin"
truncate -s 1024 "$tmpdir/f.bin"

n=$(stat -c '%s' "$tmpdir/f.bin")
[[ "$n" -eq 1024 ]] || { printf 'expected 1024 bytes, got %s\n' "$n" >&2; exit 1; }
