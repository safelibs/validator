#!/usr/bin/env bash
# @testcase: usage-jshon-r13-three-keys-via-chained-insert
# @title: jshon builds a 3-key object by chaining three -s/-i pairs
# @description: Starts from an empty object and chains -s "1" -i a -s "2" -i b -s "3" -i c through jshon to build a 3-key object, then verifies -k lists exactly the keys a, b, c (sorted) and -l reports length 3.
# @timeout: 30
# @tags: usage, json, cli, insert
# @client: jshon

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

result=$(printf '{}' | jshon -s "1" -i a -s "2" -i b -s "3" -i c)
len=$(printf '%s' "$result" | jshon -l)
[[ "$len" == "3" ]] || { printf 'expected length 3, got %s\n' "$len" >&2; exit 1; }
printf '%s' "$result" | jshon -k | sort >"$tmpdir/keys"
cat >"$tmpdir/expected" <<'EOF'
a
b
c
EOF
diff -u "$tmpdir/expected" "$tmpdir/keys"
