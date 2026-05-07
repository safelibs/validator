#!/usr/bin/env bash
# @testcase: usage-bzip2-r12-keep-roundtrip-1mb
# @title: bzip2 -k roundtrip preserves a 1MiB payload exactly
# @description: Builds a deterministic 1 MiB payload, compresses with bzip2 -k (keep input), then decompresses the .bz2 to a fresh location with bzip2 -dc and asserts byte-equal sha256 against the original.
# @timeout: 120
# @tags: usage, compression, large
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
buf = bytearray()
for i in range(1024 * 1024):
    buf.append((i * 2654435761 + 91) & 0xff)
sys.stdout.buffer.write(bytes(buf))
' >"$tmpdir/big.bin"
orig_sha=$(sha256sum "$tmpdir/big.bin" | awk '{print $1}')

bzip2 -k "$tmpdir/big.bin"
[[ -f "$tmpdir/big.bin" ]]
[[ -f "$tmpdir/big.bin.bz2" ]]

# Source unchanged.
preserved_sha=$(sha256sum "$tmpdir/big.bin" | awk '{print $1}')
[[ "$orig_sha" == "$preserved_sha" ]]

bzip2 -dc "$tmpdir/big.bin.bz2" >"$tmpdir/round.bin"
round_sha=$(sha256sum "$tmpdir/round.bin" | awk '{print $1}')
[[ "$orig_sha" == "$round_sha" ]]
