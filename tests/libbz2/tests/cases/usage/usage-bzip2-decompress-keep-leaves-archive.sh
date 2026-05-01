#!/usr/bin/env bash
# @testcase: usage-bzip2-decompress-keep-leaves-archive
# @title: bunzip2 -k preserves archive
# @description: Runs bunzip2 -k on a .bz2 file and verifies both the original archive and the newly written decompressed file are present and that the decoded content matches the pre-compression bytes.
# @timeout: 60
# @tags: usage, bunzip2, keep
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-decompress-keep-leaves-archive"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'preserve archive after decode\nline two\n' >"$tmpdir/orig.txt"
cp "$tmpdir/orig.txt" "$tmpdir/orig-snapshot.txt"
bzip2 "$tmpdir/orig.txt"
[[ ! -e "$tmpdir/orig.txt" ]]
validator_require_file "$tmpdir/orig.txt.bz2"

bunzip2 -k "$tmpdir/orig.txt.bz2"
validator_require_file "$tmpdir/orig.txt.bz2"
validator_require_file "$tmpdir/orig.txt"
cmp "$tmpdir/orig-snapshot.txt" "$tmpdir/orig.txt"
