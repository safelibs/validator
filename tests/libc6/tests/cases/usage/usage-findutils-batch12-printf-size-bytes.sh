#!/usr/bin/env bash
# @testcase: usage-findutils-batch12-printf-size-bytes
# @title: find -printf %s reports exact byte size from libc stat
# @description: Creates files with known byte sizes and verifies "find -printf '%s\n'" reports those exact sizes (libc stat path).
# @timeout: 60
# @tags: usage, findutils
# @client: findutils

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf '1234567890' >"$tmpdir/a.txt"   # 10 bytes
: >"$tmpdir/b.empty"                   # 0 bytes
printf 'XYZ' >"$tmpdir/c.txt"          # 3 bytes

find "$tmpdir" -maxdepth 1 -type f -printf '%f %s\n' | sort >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
a.txt 10
b.empty 0
c.txt 3
EOF

cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"
