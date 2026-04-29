#!/usr/bin/env bash
# @testcase: usage-bzdiff-identical
# @title: bzdiff compares matching streams
# @description: Compares two identical compressed files with bzdiff and expects no differences.
# @timeout: 180
# @tags: usage, compression
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzdiff-identical"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'same payload\n' >"$tmpdir/a.txt"
cp "$tmpdir/a.txt" "$tmpdir/b.txt"
bzip2 -c "$tmpdir/a.txt" >"$tmpdir/a.txt.bz2"
bzip2 -c "$tmpdir/b.txt" >"$tmpdir/b.txt.bz2"
bzdiff "$tmpdir/a.txt.bz2" "$tmpdir/b.txt.bz2" >"$tmpdir/out"
test ! -s "$tmpdir/out"
