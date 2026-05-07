#!/usr/bin/env bash
# @testcase: usage-jshon-r14-keys-listing-deterministic-three
# @title: jshon -k on a 3-key object lists exactly three keys
# @description: Pipes a three-key object through jshon -k and verifies the output contains exactly three lines whose sorted contents equal "alpha", "beta", "gamma", confirming the documented key listing behaviour.
# @timeout: 30
# @tags: usage, json, cli, keys
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '{"alpha":1,"beta":2,"gamma":3}' | jshon -k | sort >"$tmpdir/keys"
count=$(wc -l <"$tmpdir/keys")
[[ "$count" == "3" ]] || { printf 'expected 3 lines, got %s\n' "$count" >&2; exit 1; }
cat >"$tmpdir/expected" <<'EOF'
alpha
beta
gamma
EOF
diff -u "$tmpdir/expected" "$tmpdir/keys"
