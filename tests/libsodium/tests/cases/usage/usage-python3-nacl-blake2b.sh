#!/usr/bin/env bash
# @testcase: usage-python3-nacl-blake2b
# @title: PyNaCl BLAKE2b hash
# @description: Computes a BLAKE2b digest with PyNaCl and verifies hex output length.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-blake2b"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.hash import blake2b
from nacl.encoding import HexEncoder
digest = blake2b(b"payload", encoder=HexEncoder)
assert len(digest) == 64
print(digest[:16].decode())
PY
