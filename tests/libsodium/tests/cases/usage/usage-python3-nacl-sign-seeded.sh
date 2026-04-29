#!/usr/bin/env bash
# @testcase: usage-python3-nacl-sign-seeded
# @title: PyNaCl seeded signing key
# @description: Builds a deterministic signing key from seed bytes and verifies a signed payload.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-sign-seeded"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.signing import SigningKey
seed = b"\x01" * 32
signing_key = SigningKey(seed)
signed = signing_key.sign(b"seeded payload")
assert signing_key.verify_key.verify(signed) == b"seeded payload"
print(len(signed.signature))
PY
