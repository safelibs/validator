#!/usr/bin/env bash
# @testcase: usage-bzip2-r18-bzcat-binary-256-bytes-stdout
# @title: bzcat reproduces every 0..255 byte value through a stdin pipe
# @description: Builds a 256-byte file containing each octet from 0 to 255 exactly once, compresses it with bzip2 -c through stdin, then decompresses with bzcat on the resulting archive and asserts the recovered bytes are identical (sha256 match) — locking in binary fidelity across the full byte range.
# @timeout: 30
# @tags: usage, bzcat, binary, fidelity, r18
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/in.bin" <<'PY'
import sys
with open(sys.argv[1], 'wb') as f:
    f.write(bytes(range(256)))
PY

want_sha=$(sha256sum "$tmpdir/in.bin" | awk '{print $1}')

bzip2 -c <"$tmpdir/in.bin" >"$tmpdir/in.bz2"
bzcat "$tmpdir/in.bz2" >"$tmpdir/out.bin"

got_sha=$(sha256sum "$tmpdir/out.bin" | awk '{print $1}')
[[ "$got_sha" == "$want_sha" ]] || {
    printf 'sha mismatch: want=%s got=%s\n' "$want_sha" "$got_sha" >&2
    exit 1
}

bytes=$(wc -c <"$tmpdir/out.bin")
[[ "$bytes" -eq 256 ]] || {
    printf 'expected 256 bytes recovered, got %s\n' "$bytes" >&2
    exit 1
}
