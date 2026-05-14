#!/usr/bin/env bash
# @testcase: usage-gio-r18-copy-then-info-shows-destination-size
# @title: gio copy followed by gio info reports the same size at the destination
# @description: Writes a fixed-payload source file in a tmpdir, runs gio copy to a destination path, and asserts gio info -a standard::size at the destination reports the exact source byte count, exercising the gio copy plus info pipeline as a size-preservation check.
# @timeout: 60
# @tags: usage, gio, copy, info, r18
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

payload='r18-gio-copy-then-info-marker-payload'
printf '%s' "$payload" >"$tmpdir/src.txt"
expected=$(stat -c '%s' "$tmpdir/src.txt")

gio copy "$tmpdir/src.txt" "$tmpdir/dst.txt"
gio info -a standard::size "$tmpdir/dst.txt" >"$tmpdir/info.txt"
validator_assert_contains "$tmpdir/info.txt" "standard::size: $expected"
