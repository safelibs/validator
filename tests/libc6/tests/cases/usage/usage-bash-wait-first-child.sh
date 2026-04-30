#!/usr/bin/env bash
# @testcase: usage-bash-wait-first-child
# @title: bash wait -n first child
# @description: Spawns two background children and verifies bash wait -n returns when the earliest exits.
# @timeout: 180
# @tags: usage, shell, process
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-wait-first-child"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash -c '
set -euo pipefail
( sleep 0.2; echo first ) &
( sleep 2; echo second ) &
wait -n
echo done
' >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'first'
validator_assert_contains "$tmpdir/out" 'done'
if grep -Fq 'second' "$tmpdir/out"; then exit 1; fi
