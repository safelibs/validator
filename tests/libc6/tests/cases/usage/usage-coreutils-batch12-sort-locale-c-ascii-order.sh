#!/usr/bin/env bash
# @testcase: usage-coreutils-batch12-sort-locale-c-ascii-order
# @title: sort under LC_ALL=C uses pure ASCII byte order
# @description: Sorts a list of strings with mixed case and digits under LC_ALL=C and verifies the result follows ASCII byte order (digits before uppercase before lowercase).
# @timeout: 60
# @tags: usage, coreutils, locale, sort
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
banana
Apple
1apple
Banana
apple
EOF

LC_ALL=C sort "$tmpdir/in.txt" >"$tmpdir/out.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
1apple
Apple
Banana
apple
banana
EOF

cmp "$tmpdir/out.txt" "$tmpdir/expected.txt"
