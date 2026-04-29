#!/usr/bin/env bash
# @testcase: usage-bash-case-switch
# @title: bash case dispatch
# @description: Executes a bash case statement and verifies the matching branch output.
# @timeout: 180
# @tags: usage, bash, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-case-switch"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash >"$tmpdir/out" <<'BASH'
value=beta
case "$value" in
  alpha) echo no ;;
  beta) echo matched-beta ;;
  *) echo no ;;
esac
BASH
validator_assert_contains "$tmpdir/out" 'matched-beta'
