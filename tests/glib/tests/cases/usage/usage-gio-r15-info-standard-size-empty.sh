#!/usr/bin/env bash
# @testcase: usage-gio-r15-info-standard-size-empty
# @title: gio info reports standard::size 0 for an empty regular file
# @description: Creates a freshly truncated empty file and asserts gio info exposes the standard::size attribute as exactly 0 bytes for it.
# @timeout: 60
# @tags: usage, gio, info
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/empty.bin"
gio info --attributes='standard::size' "$tmpdir/empty.bin" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'standard::size: 0'
