#!/usr/bin/env bash
# @testcase: usage-bzip2-r20-bzip2-stdout-pipeline-sha256-matches-source
# @title: bzip2 -c | bzip2 -dc pipeline preserves the SHA-256 of a deterministic 16 KiB payload
# @description: Generates 16384 bytes of deterministic binary content, pipes it through bzip2 -c into bzip2 -dc, and asserts the SHA-256 of the pipeline output equals the SHA-256 of the source, exercising the chained compress-then-decompress pipeline fidelity via cryptographic-checksum identity at a non-trivial size distinct from prior fixed-string roundtrips.
# @timeout: 30
# @tags: usage, bzip2, pipeline, sha256, r20
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c '
import sys
data = bytes(((i * 31) ^ ((i >> 5) * 17)) & 0xff for i in range(16384))
sys.stdout.buffer.write(data)
' >"$tmpdir/src.bin"

src_sha=$(sha256sum "$tmpdir/src.bin" | awk '{print $1}')
bzip2 -c <"$tmpdir/src.bin" | bzip2 -dc >"$tmpdir/round.bin"
round_sha=$(sha256sum "$tmpdir/round.bin" | awk '{print $1}')

[[ "$src_sha" == "$round_sha" ]] || {
    printf 'sha mismatch src=%s round=%s\n' "$src_sha" "$round_sha" >&2
    exit 1
}
