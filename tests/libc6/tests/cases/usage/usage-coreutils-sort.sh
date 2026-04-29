#!/usr/bin/env bash
# @testcase: usage-coreutils-sort
# @title: coreutils sorts text
# @description: Sorts lines with GNU sort and verifies the ordered output.
# @timeout: 120
# @tags: usage, cli
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-coreutils-sort"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'b\na\nc\n' | sort >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" $'a\nb\nc'
