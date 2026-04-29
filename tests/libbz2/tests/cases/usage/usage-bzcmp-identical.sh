#!/usr/bin/env bash
# @testcase: usage-bzcmp-identical
# @title: bzcmp identical archives
# @description: Compares two identical compressed files with bzcmp and verifies no diff output is produced.
# @timeout: 180
# @tags: usage, compression, cli
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzcmp-identical"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'same payload\n' >"$tmpdir/a.txt"
cp "$tmpdir/a.txt" "$tmpdir/b.txt"
bzip2 -c "$tmpdir/a.txt" >"$tmpdir/a.txt.bz2"
bzip2 -c "$tmpdir/b.txt" >"$tmpdir/b.txt.bz2"
bzcmp "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out"
test ! -s "$tmpdir/out"
