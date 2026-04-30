#!/usr/bin/env bash
# @testcase: usage-bash-compgen-command-listing
# @title: bash compgen -c command listing
# @description: Uses bash compgen -c to list available commands and verifies common builtins/utilities are present.
# @timeout: 180
# @tags: usage, shell
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-compgen-command-listing"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash -lc 'compgen -c | sort -u' >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'printf'
validator_assert_contains "$tmpdir/out" 'echo'
