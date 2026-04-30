#!/usr/bin/env bash
# @testcase: usage-gawk-gensub-backref
# @title: gawk gensub backreference rewrite
# @description: Rewrites name=value pairs to value:name with gawk gensub backreferences and verifies the transformed output.
# @timeout: 180
# @tags: usage, gawk, text
# @client: gawk

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gawk-gensub-backref"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
host=alpha
port=8080
mode=fast
EOF

gawk '{ print gensub(/^([a-z]+)=(.+)$/, "\\2:\\1", 1) }' "$tmpdir/in.txt" >"$tmpdir/out"

validator_assert_contains "$tmpdir/out" 'alpha:host'
validator_assert_contains "$tmpdir/out" '8080:port'
validator_assert_contains "$tmpdir/out" 'fast:mode'
