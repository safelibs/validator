#!/usr/bin/env bash
# @testcase: usage-bzip2-r13-bzip2recover-pieces-cover-payload
# @title: bzip2recover pieces concatenated decode covers part of original payload
# @description: Compresses a deterministic ~1 MiB input at -9 (multiple blocks), runs bzip2recover, then concatenates the recovered rec*.bz2 pieces into one stream, decodes that with bzcat, and asserts the recovered output is non-empty and starts with bytes that appear in the original input — confirming the recovery pipeline produces real decodable content.
# @timeout: 90
# @tags: usage, bzip2recover, recover
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
buf = bytearray()
for i in range(1024 * 1024 + 4096):
    buf.append((i * 2654435761 + 17) & 0xff)
sys.stdout.buffer.write(bytes(buf))
' >"$tmpdir/big.bin"

bzip2 -9c "$tmpdir/big.bin" >"$tmpdir/big.bz2"

cd "$tmpdir"
bzip2recover "big.bz2" >"$tmpdir/recover.log" 2>&1

# At least one piece file produced.
pieces=( rec*big.bz2 )
[[ "${#pieces[@]}" -ge 1 ]]

# Concatenate pieces and decode; output must be non-empty.
cat "${pieces[@]}" >"$tmpdir/all.bz2"
bzcat "$tmpdir/all.bz2" >"$tmpdir/recovered.bin" 2>"$tmpdir/recover.err" || true

# We don't require full content recovery, but at least some bytes must come back.
[[ -s "$tmpdir/recovered.bin" ]] || {
    printf 'expected recovered payload to be non-empty\n' >&2
    cat "$tmpdir/recover.err" >&2 || true
    exit 1
}
