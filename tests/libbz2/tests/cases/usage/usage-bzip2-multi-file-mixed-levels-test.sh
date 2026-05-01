#!/usr/bin/env bash
# @testcase: usage-bzip2-multi-file-mixed-levels-test
# @title: bzip2 -t accepts mixed-level archives
# @description: Compresses three distinct payloads at block levels 1, 5, and 9 and verifies a single bzip2 -t invocation accepts all three resulting archives.
# @timeout: 120
# @tags: usage, bzip2, levels
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-multi-file-mixed-levels-test"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'tiny payload one\n' >"$tmpdir/one.txt"
python3 -c 'print("medium\n"*4096)' >"$tmpdir/two.txt"
python3 -c 'print("nine "*8192)' >"$tmpdir/three.txt"

bzip2 -1 -k "$tmpdir/one.txt"
bzip2 -5 -k "$tmpdir/two.txt"
bzip2 -9 -k "$tmpdir/three.txt"

bzip2 -t "$tmpdir/one.txt.bz2" "$tmpdir/two.txt.bz2" "$tmpdir/three.txt.bz2"
