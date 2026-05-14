#!/usr/bin/env bash
# @testcase: usage-libarchive-tools-r18-xz-test-flag-nonzero-on-corrupt
# @title: xz -t exits non-zero on a deliberately corrupted .xz file
# @description: Builds a valid xz stream, flips a byte in the middle of the file, runs xz -t on the corrupted archive, and asserts the integrity check exits non-zero — pinning the failure detection path through the liblzma decoder.
# @timeout: 60
# @tags: usage, xz, test, integrity, corrupt, r18
# @client: libarchive-tools

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 -c "import sys; sys.stdout.buffer.write(b'r18-corrupt-payload-' * 100)" >"$tmpdir/in.txt"
xz -c "$tmpdir/in.txt" >"$tmpdir/in.xz"

python3 - "$tmpdir/in.xz" <<'PY'
import sys
p = sys.argv[1]
data = bytearray(open(p, 'rb').read())
# Flip a byte well past the header to corrupt the LZMA payload.
i = max(20, len(data) // 2)
data[i] ^= 0xFF
open(p, 'wb').write(bytes(data))
PY

set +e
xz -t "$tmpdir/in.xz" 2>"$tmpdir/err.txt"
rc=$?
set -e

[[ "$rc" -ne 0 ]] || {
  printf 'expected non-zero xz -t on corrupted file\n' >&2; exit 1;
}
