#!/usr/bin/env bash
# @testcase: usage-bzip2-batch12-test-corrupt-byte-flips-fail
# @title: bzip2 -t rejects an archive with a flipped data byte
# @description: Compresses a payload, flips a single byte deep inside the archive, and verifies bzip2 -t exits nonzero (reports corruption).
# @timeout: 60
# @tags: usage, compression, error
# @client: bzip2

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(b'AAAA' * 1024)" >"$tmpdir/in.bin"
bzip2 -c "$tmpdir/in.bin" >"$tmpdir/out.bz2"

size=$(stat -c '%s' "$tmpdir/out.bz2")
mid=$((size / 2))

python3 - "$tmpdir/out.bz2" "$mid" <<'PY'
import sys
path, idx = sys.argv[1], int(sys.argv[2])
data = bytearray(open(path, "rb").read())
data[idx] ^= 0xff
open(path, "wb").write(bytes(data))
PY

set +e
bzip2 -t "$tmpdir/out.bz2" 2>"$tmpdir/err.log"
rc=$?
set -e
[[ "$rc" -ne 0 ]]
