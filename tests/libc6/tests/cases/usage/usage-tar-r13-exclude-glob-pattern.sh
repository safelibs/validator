#!/usr/bin/env bash
# @testcase: usage-tar-r13-exclude-glob-pattern
# @title: tar --exclude omits members matching a glob pattern from the archive
# @description: Creates a directory of mixed file extensions, builds a tar archive with --exclude='*.log', and asserts the archive listing contains only the non-excluded files.
# @timeout: 60
# @tags: usage, tar, exclude
# @client: tar

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

LC_ALL=C
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
printf 'a\n' >"$tmpdir/src/keep1.txt"
printf 'b\n' >"$tmpdir/src/keep2.txt"
printf 'x\n' >"$tmpdir/src/skip1.log"
printf 'y\n' >"$tmpdir/src/skip2.log"

LC_ALL=C tar --exclude='*.log' \
  -C "$tmpdir" -cf "$tmpdir/out.tar" src

LC_ALL=C tar -tf "$tmpdir/out.tar" \
  | LC_ALL=C grep -v '/$' \
  | LC_ALL=C sort >"$tmpdir/got.txt"

cat >"$tmpdir/expected.txt" <<'EOF'
src/keep1.txt
src/keep2.txt
EOF

cmp "$tmpdir/got.txt" "$tmpdir/expected.txt"
