#!/usr/bin/env bash
# @testcase: usage-gio-r16-info-display-name-attribute
# @title: gio info --attributes=standard::display-name surfaces the basename verbatim
# @description: Creates a file with a distinctive basename "r16-display.bin" under a tmpdir and asserts gio info --attributes=standard::display-name reports the basename string verbatim, exercising the display-name attribute on a regular file (where it falls back to basename).
# @timeout: 60
# @tags: usage, gio, info, display-name
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

: >"$tmpdir/r16-display.bin"
gio info --attributes='standard::display-name' "$tmpdir/r16-display.bin" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'standard::display-name:'
validator_assert_contains "$tmpdir/out" 'r16-display.bin'
