#!/usr/bin/env bash
# @testcase: usage-bzgrep-count-matches-multiple
# @title: bzgrep -c counts matches across multiple compressed files
# @description: Searches two compressed inputs with bzgrep -c and verifies the per-file match counts are emitted accurately.
# @timeout: 180
# @tags: usage, search, count
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/one.txt" <<'EOF'
needle alpha
filler
needle beta
filler
needle gamma
EOF

cat >"$tmpdir/two.txt" <<'EOF'
filler
needle delta
filler
EOF

bzip2 -zk "$tmpdir/one.txt"
bzip2 -zk "$tmpdir/two.txt"

( cd "$tmpdir" && bzgrep -c needle one.txt.bz2 two.txt.bz2 ) >"$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'one.txt.bz2:3'
validator_assert_contains "$tmpdir/out" 'two.txt.bz2:1'
[[ $(wc -l <"$tmpdir/out") -eq 2 ]]
