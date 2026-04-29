#!/usr/bin/env bash
# @testcase: usage-bzgrep-invert-match
# @title: bzgrep invert match
# @description: Uses bzgrep -v on a compressed text stream and verifies non-matching lines appear while the excluded line is omitted.
# @timeout: 180
# @tags: usage, bzip2, search
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzgrep-invert-match"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'alpha\nbeta\ngamma\n' >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.txt.bz2"
bzgrep -v 'beta' "$tmpdir/in.txt.bz2" >"$tmpdir/out"
grep -Fxq 'alpha' "$tmpdir/out"
grep -Fxq 'gamma' "$tmpdir/out"
if grep -Fxq 'beta' "$tmpdir/out"; then exit 1; fi
