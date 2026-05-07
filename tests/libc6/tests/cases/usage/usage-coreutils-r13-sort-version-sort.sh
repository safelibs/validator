#!/usr/bin/env bash
# @testcase: usage-coreutils-r13-sort-version-sort
# @title: coreutils sort --version-sort orders dotted version strings naturally
# @description: Feeds a list of dotted release identifiers to sort --version-sort under LC_ALL=C and asserts the output is in natural version order rather than ASCIIbetical order.
# @timeout: 60
# @tags: usage, coreutils, sort, version
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'EOF'
v1.10.0
v1.2.0
v1.2.10
v1.2.2
v1.1.0
EOF

LC_ALL=C sort --version-sort "$tmpdir/in.txt" >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
v1.1.0
v1.2.0
v1.2.2
v1.2.10
v1.10.0
EOF

cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"
