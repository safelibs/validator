#!/usr/bin/env bash
# @testcase: usage-gio-r17-info-unix-nlink-numeric-on-regular-file
# @title: gio info --attributes=unix::nlink reports a numeric link count on a regular file
# @description: Creates a regular file under a tmpdir, runs gio info --attributes=unix::nlink, and asserts the rendered attribute value is a positive integer (at least 1), exercising the unix::nlink attribute on a freshly created file without pinning the exact value.
# @timeout: 60
# @tags: usage, gio, info, unix-nlink
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/nlink.bin"
gio info --attributes='unix::nlink' "$tmpdir/nlink.bin" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'unix::nlink:'

value=$(grep -E 'unix::nlink:' "$tmpdir/out" | head -n1 | awk -F': ' '{print $2}' | tr -d '[:space:]')
[[ "$value" =~ ^[0-9]+$ ]] || {
    printf 'unix::nlink value not numeric: %q\n' "$value" >&2
    exit 1
}
(( value >= 1 )) || {
    printf 'unix::nlink value < 1: %s\n' "$value" >&2
    exit 1
}
