#!/usr/bin/env bash
# @testcase: usage-sed-transform
# @title: sed transforms stream
# @description: Rewrites a token in stream input with sed.
# @timeout: 120
# @tags: usage, cli
# @client: sed

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-sed-transform"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'name=old\n' | sed 's/old/new/' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'name=new'
