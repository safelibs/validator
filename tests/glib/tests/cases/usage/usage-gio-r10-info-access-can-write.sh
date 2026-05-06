#!/usr/bin/env bash
# @testcase: usage-gio-r10-info-access-can-write
# @title: gio info reports access::can-write TRUE for writable file
# @description: Creates a writable regular file and verifies "gio info -a access::can-write" reports TRUE.
# @timeout: 60
# @tags: usage, gio, info
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'writable\n' >"$tmpdir/file.txt"
chmod 0644 "$tmpdir/file.txt"
gio info -a access::can-write "$tmpdir/file.txt" >"$tmpdir/out.txt"
grep -E 'access::can-write:[[:space:]]*TRUE' "$tmpdir/out.txt" >/dev/null
