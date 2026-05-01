#!/usr/bin/env bash
# @testcase: usage-bash-assoc-array-declare
# @title: bash associative array via declare -A
# @description: Builds a bash associative array using declare -A, populates entries, and verifies indexed lookups and the keys-listing expansion.
# @timeout: 120
# @tags: usage, bash, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-assoc-array-declare"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash >"$tmpdir/out" <<'BASH_EOF'
declare -A colors
colors[red]='#ff0000'
colors[green]='#00ff00'
colors[blue]='#0000ff'
printf 'count=%d\n' "${#colors[@]}"
printf 'red=%s\n' "${colors[red]}"
printf 'green=%s\n' "${colors[green]}"
printf 'keys='
for k in $(printf '%s\n' "${!colors[@]}" | sort); do
  printf '%s ' "$k"
done
printf '\n'
BASH_EOF

validator_assert_contains "$tmpdir/out" 'count=3'
validator_assert_contains "$tmpdir/out" 'red=#ff0000'
validator_assert_contains "$tmpdir/out" 'green=#00ff00'
validator_assert_contains "$tmpdir/out" 'keys=blue green red '
