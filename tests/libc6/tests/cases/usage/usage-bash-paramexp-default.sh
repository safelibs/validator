#!/usr/bin/env bash
# @testcase: usage-bash-paramexp-default
# @title: bash parameter expansion default value
# @description: Exercises ${var:-default} and ${var:=default} parameter expansion forms to verify libc-backed string substitution semantics on unset and empty variables.
# @timeout: 120
# @tags: usage, bash, libc
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bash-paramexp-default"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

bash >"$tmpdir/out" <<'BASH_EOF'
unset MAYBE
empty=""
printf 'a=%s\n' "${MAYBE:-fallback-a}"
printf 'b=%s\n' "${empty:-fallback-b}"
preset="real"
printf 'c=%s\n' "${preset:-fallback-c}"

unset ASSIGN
: "${ASSIGN:=assigned}"
printf 'd=%s\n' "$ASSIGN"
BASH_EOF

validator_assert_contains "$tmpdir/out" 'a=fallback-a'
validator_assert_contains "$tmpdir/out" 'b=fallback-b'
validator_assert_contains "$tmpdir/out" 'c=real'
validator_assert_contains "$tmpdir/out" 'd=assigned'
