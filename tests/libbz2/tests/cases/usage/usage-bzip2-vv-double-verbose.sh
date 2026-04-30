#!/usr/bin/env bash
# @testcase: usage-bzip2-vv-double-verbose
# @title: bzip2 -vv double verbose compress
# @description: Compresses a multi-block payload with bzip2 -vv and verifies the second verbosity level emits per-block CRC accounting alongside the final combined CRC line.
# @timeout: 180
# @tags: usage, bzip2, verbose
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-vv-double-verbose"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.write('vv-verbose payload row\n' * 64)" >"$tmpdir/in.txt"

bzip2 -vv -c "$tmpdir/in.txt" >"$tmpdir/in.bz2" 2>"$tmpdir/err"

# Roundtrip must still match.
bunzip2 -c "$tmpdir/in.bz2" >"$tmpdir/round.txt"
cmp "$tmpdir/in.txt" "$tmpdir/round.txt"

# -vv prints per-block accounting and a final combined CRC.
validator_assert_contains "$tmpdir/err" 'block 1'
validator_assert_contains "$tmpdir/err" 'crc'
validator_assert_contains "$tmpdir/err" 'combined CRC'
validator_assert_contains "$tmpdir/err" 'bits/byte'
