#!/usr/bin/env bash
# @testcase: usage-bash-parameter-trim
# @title: bash parameter trim
# @description: Uses bash parameter expansion to trim a filename suffix and verifies the shortened value.
# @timeout: 180
# @tags: usage, bash, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-parameter-trim"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash >"$tmpdir/out" <<'SH'
value='alpha.beta.txt'
printf '%s\n' "${value%.txt}"
SH
validator_assert_contains "$tmpdir/out" 'alpha.beta'
