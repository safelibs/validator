#!/usr/bin/env bash
# @testcase: usage-python3-nacl-sha256
# @title: PyNaCl SHA-256 digest
# @description: Hashes a short payload with PyNaCl SHA-256 helpers and verifies the expected digest.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-sha256"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.hash import sha256
from nacl.encoding import HexEncoder
digest = sha256(b"abc", encoder=HexEncoder).decode()
assert digest == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
print(digest[:16])
PY
