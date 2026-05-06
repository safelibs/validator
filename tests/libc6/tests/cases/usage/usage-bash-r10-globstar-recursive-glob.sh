#!/usr/bin/env bash
# @testcase: usage-bash-r10-globstar-recursive-glob
# @title: bash globstar ** descends through subdirectories via libc readdir
# @description: Enables shopt -s globstar and verifies the ** pattern enumerates files at multiple depths in a fixture tree, exercising bash's libc readdir/opendir-backed glob expansion.
# @timeout: 60
# @tags: usage, bash, glob
# @client: bash

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/a/b/c"
: >"$tmpdir/a/x.log"
: >"$tmpdir/a/b/y.log"
: >"$tmpdir/a/b/c/z.log"

shopt -s globstar nullglob
matches=("$tmpdir"/**/*.log)
LC_ALL=C printf '%s\n' "${matches[@]}" | LC_ALL=C sort >"$tmpdir/got.txt"

LC_ALL=C cat >"$tmpdir/want.txt" <<EOF
$tmpdir/a/b/c/z.log
$tmpdir/a/b/y.log
$tmpdir/a/x.log
EOF

diff -u "$tmpdir/want.txt" "$tmpdir/got.txt"
