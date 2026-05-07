#!/usr/bin/env bash
# @testcase: usage-gio-r12-copy-overwrite-replaces-content
# @title: gio copy overwrites destination content when target exists
# @description: Creates source and destination files with different payloads, runs gio copy with no special flags, and verifies the destination now matches the source byte-for-byte.
# @timeout: 60
# @tags: usage, gio, copy
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'r12-source-bytes\n' >"$tmpdir/src.txt"
printf 'previous-target-bytes\n' >"$tmpdir/dst.txt"

gio copy "$tmpdir/src.txt" "$tmpdir/dst.txt"
cmp "$tmpdir/src.txt" "$tmpdir/dst.txt"
