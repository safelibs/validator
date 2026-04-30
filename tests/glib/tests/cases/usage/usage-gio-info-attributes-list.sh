#!/usr/bin/env bash
# @testcase: usage-gio-info-attributes-list
# @title: gio info attributes list
# @description: Reads multiple file attributes through gio info --attributes and verifies each requested namespace appears.
# @timeout: 180
# @tags: usage, gio
# @client: gio

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gio-info-attributes-list"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'attributes payload\n' >"$tmpdir/input.txt"
gio info --attributes='standard::name,standard::size,unix::mode' "$tmpdir/input.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'standard::name:'
validator_assert_contains "$tmpdir/out" 'standard::size:'
validator_assert_contains "$tmpdir/out" 'unix::mode:'
validator_assert_contains "$tmpdir/out" 'input.txt'
