#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r21-xzgrep-matches-pattern
# @title: xzgrep finds a literal pattern inside a .xz-compressed text file
# @description: Compresses a small text file with xz and uses xzgrep to find a substring pattern in the compressed file, asserting the matching line is returned, pinning the xzgrep helper's liblzma-backed transparent decompression.
# @timeout: 60
# @tags: usage, xz, xzgrep, r21
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat >"$tmpdir/in.txt" <<'TXT'
alpha line
beta line
gamma needle here
delta line
TXT
xz -k "$tmpdir/in.txt"
validator_require_file "$tmpdir/in.txt.xz"

xzgrep needle "$tmpdir/in.txt.xz" >"$tmpdir/out.txt"
grep -Fq 'gamma needle here' "$tmpdir/out.txt"
