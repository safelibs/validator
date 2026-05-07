#!/usr/bin/env bash
# @testcase: usage-sed-r14-multiple-e-expressions
# @title: sed chains multiple -e expressions in declared order
# @description: Pipes a fixed input through sed with three -e substitution expressions under LC_ALL=C and asserts each substitution is applied in order to produce the expected combined output, exercising sed's libc-backed file streaming and expression script chaining.
# @timeout: 60
# @tags: usage, sed, expressions
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'apple banana cherry\n' >"$tmpdir/in.txt"

LC_ALL=C sed \
  -e 's/apple/A/' \
  -e 's/banana/B/' \
  -e 's/cherry/C/' \
  "$tmpdir/in.txt" >"$tmpdir/got.txt"

got=$(cat "$tmpdir/got.txt")
[[ "$got" == "A B C" ]]
