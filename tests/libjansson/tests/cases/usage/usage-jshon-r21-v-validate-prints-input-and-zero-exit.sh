#!/usr/bin/env bash
# @testcase: usage-jshon-r21-v-validate-prints-input-and-zero-exit
# @title: jshon -V validates well-formed input, exits zero, and reprints it
# @description: Pipes the JSON object {"a":1,"b":[true,null]} through jshon -V and asserts the command exits zero AND that the captured stdout contains "a", "b", "true", and "null" - locking in libjansson-backed jshon's -V validate path that confirms structural well-formedness while still re-emitting the parsed document.
# @timeout: 30
# @tags: usage, json, cli, validate, r21
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"a":1,"b":[true,null]}' | jshon -V >"$tmpdir/out" 2>"$tmpdir/err"
validator_assert_contains "$tmpdir/out" '"a"'
validator_assert_contains "$tmpdir/out" '"b"'
validator_assert_contains "$tmpdir/out" 'true'
validator_assert_contains "$tmpdir/out" 'null'
