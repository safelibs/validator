#!/usr/bin/env bash
# @testcase: usage-bzip2-stdout-pipe-into-bunzip2
# @title: bzip2 piped directly to bunzip2
# @description: Pipes bzip2 -c output straight into bunzip2 -c without any intermediate file and verifies the decoded byte stream matches the original payload exactly.
# @timeout: 120
# @tags: usage, bzip2, pipeline
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-bzip2-stdout-pipe-into-bunzip2"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
data = bytes(range(256)) * 256
sys.stdout.buffer.write(data)
' >"$tmpdir/in.bin"

orig_size=$(wc -c <"$tmpdir/in.bin")
[[ $orig_size -eq 65536 ]]

bzip2 -c "$tmpdir/in.bin" | bunzip2 -c >"$tmpdir/out.bin"
out_size=$(wc -c <"$tmpdir/out.bin")
[[ $out_size -eq $orig_size ]] || {
  printf 'size mismatch: in=%d out=%d\n' "$orig_size" "$out_size" >&2
  exit 1
}
cmp "$tmpdir/in.bin" "$tmpdir/out.bin"
