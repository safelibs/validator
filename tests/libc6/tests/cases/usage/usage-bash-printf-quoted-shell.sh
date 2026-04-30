#!/usr/bin/env bash
# @testcase: usage-bash-printf-quoted-shell
# @title: bash printf quoted shell escape
# @description: Uses bash printf %q to escape a string with whitespace and special characters and verifies the shell-safe form.
# @timeout: 180
# @tags: usage, bash, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-printf-quoted-shell"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '%q\n' 'hello world' >"$tmpdir/space.out"
printf '%q\n' "it's a test" >"$tmpdir/quote.out"
printf '%q\n' '$dangerous' >"$tmpdir/dollar.out"

validator_assert_contains "$tmpdir/space.out" 'hello\ world'
validator_assert_contains "$tmpdir/quote.out" "\\'"
validator_assert_contains "$tmpdir/dollar.out" '\$dangerous'
