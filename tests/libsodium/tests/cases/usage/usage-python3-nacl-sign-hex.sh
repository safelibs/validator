#!/usr/bin/env bash
# @testcase: usage-python3-nacl-sign-hex
# @title: PyNaCl sign hex
# @description: Exercises pynacl sign hex through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-sign-hex"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.encoding import HexEncoder
from nacl.signing import SigningKey
sk = SigningKey.generate()
signature = sk.sign(b'hex payload').signature.hex()
assert len(signature) == 128
print(signature[:16])
PY
