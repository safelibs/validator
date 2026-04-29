#!/usr/bin/env bash
# @testcase: usage-bash-script-exec
# @title: Bash executes script
# @description: Runs a short Bash program that performs arithmetic and prints a value.
# @timeout: 120
# @tags: usage, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-script-exec"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash -lc 'printf "shell=%d\n" "$((6 * 7))"' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'shell=42'
