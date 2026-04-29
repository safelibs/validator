#!/usr/bin/env bash
# @testcase: usage-bash-printf-hex-format
# @title: bash printf hex format
# @description: Formats an integer as hexadecimal with bash printf and verifies the lowercase ff representation.
# @timeout: 180
# @tags: usage, bash, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-printf-hex-format"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '%x\n' 255 >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'ff'
