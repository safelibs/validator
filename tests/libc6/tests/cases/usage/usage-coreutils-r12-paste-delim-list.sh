#!/usr/bin/env bash
# @testcase: usage-coreutils-r12-paste-delim-list
# @title: coreutils paste -d cycles through delimiter list
# @description: Pastes three input files together with paste -d',;' and verifies the cycled delimiter list interleaves the columns with comma then semicolon between fields.
# @timeout: 60
# @tags: usage, coreutils, paste
# @client: coreutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'a1\na2\n' >"$tmpdir/A"
printf 'b1\nb2\n' >"$tmpdir/B"
printf 'c1\nc2\n' >"$tmpdir/C"

LC_ALL=C paste -d',;' "$tmpdir/A" "$tmpdir/B" "$tmpdir/C" >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
a1,b1;c1
a2,b2;c2
EOF

cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"
