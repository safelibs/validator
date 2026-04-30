#!/usr/bin/env bash
# @testcase: usage-bzip2-explicit-dev-stdin
# @title: bzip2 explicit /dev/stdin path
# @description: Decompresses a bzip2 stream by passing /dev/stdin as the explicit input path and verifies the recovered plaintext matches the original.
# @timeout: 180
# @tags: usage, bzip2, stream
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-explicit-dev-stdin"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.write('explicit dev stdin payload line\n' * 8)" >"$tmpdir/in.txt"
bzip2 -c "$tmpdir/in.txt" >"$tmpdir/in.bz2"

# Pass /dev/stdin as an explicit path argument while feeding the stream on fd 0.
bzip2 -dc /dev/stdin <"$tmpdir/in.bz2" >"$tmpdir/round.txt"
cmp "$tmpdir/in.txt" "$tmpdir/round.txt"
