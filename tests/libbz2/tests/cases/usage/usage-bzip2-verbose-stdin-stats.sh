#!/usr/bin/env bash
# @testcase: usage-bzip2-verbose-stdin-stats
# @title: bzip2 verbose stdin stats
# @description: Compresses stdin with bzip2 -v and verifies the verbose stats line reports the stdin label and bits/byte ratio.
# @timeout: 180
# @tags: usage, bzip2, verbose
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-verbose-stdin-stats"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.write('verbose stdin payload\n' * 32)" >"$tmpdir/in.txt"
bzip2 -v -c <"$tmpdir/in.txt" >"$tmpdir/out.bz2" 2>"$tmpdir/err"

# Output stream must round-trip cleanly.
bunzip2 -c <"$tmpdir/out.bz2" >"$tmpdir/round.txt"
cmp "$tmpdir/in.txt" "$tmpdir/round.txt"

# Verbose stats line must mention the stdin label and a bits/byte ratio.
validator_assert_contains "$tmpdir/err" '(stdin)'
validator_assert_contains "$tmpdir/err" 'bits/byte'
validator_assert_contains "$tmpdir/err" 'in,'
validator_assert_contains "$tmpdir/err" 'out.'
