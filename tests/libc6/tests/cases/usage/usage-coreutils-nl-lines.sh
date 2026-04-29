#!/usr/bin/env bash
# @testcase: usage-coreutils-nl-lines
# @title: coreutils nl numbering
# @description: Numbers text lines with nl and checks the emitted line numbers.
# @timeout: 180
# @tags: usage, coreutils, text
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-nl-lines"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\n' >"$tmpdir/in.txt"
nl -ba "$tmpdir/in.txt" >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" '1'
validator_assert_contains "$tmpdir/out" 'beta'
