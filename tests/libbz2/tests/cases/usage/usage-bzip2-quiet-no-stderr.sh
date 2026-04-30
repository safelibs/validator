#!/usr/bin/env bash
# @testcase: usage-bzip2-quiet-no-stderr
# @title: bzip2 quiet no stderr
# @description: Runs bzip2 --quiet on a successful compress+test cycle and verifies the command emits no diagnostics on stderr while still producing a valid compressed stream.
# @timeout: 180
# @tags: usage, bzip2, quiet
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-quiet-no-stderr"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

printf 'quiet flag payload\n' >"$tmpdir/in.txt"

# Quiet compress to stdout: stderr must be empty.
bzip2 --quiet -c "$tmpdir/in.txt" >"$tmpdir/in.bz2" 2>"$tmpdir/err.compress"
[[ ! -s "$tmpdir/err.compress" ]]

# Quiet integrity check on the resulting stream: stderr must also be empty.
bzip2 --quiet -t "$tmpdir/in.bz2" 2>"$tmpdir/err.test"
[[ ! -s "$tmpdir/err.test" ]]

# Round-trip must still recover the payload.
bunzip2 -c "$tmpdir/in.bz2" >"$tmpdir/round.txt"
cmp "$tmpdir/in.txt" "$tmpdir/round.txt"
