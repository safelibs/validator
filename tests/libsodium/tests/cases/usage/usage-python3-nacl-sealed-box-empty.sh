#!/usr/bin/env bash
# @testcase: usage-python3-nacl-sealed-box-empty
# @title: python3-nacl sealed box empty payload
# @description: Exercises python3-nacl sealed box empty payload through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-sealed-box-empty"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.public import PrivateKey, SealedBox
recipient = PrivateKey.generate()
sealed = SealedBox(recipient.public_key).encrypt(b'')
plain = SealedBox(recipient).decrypt(sealed)
assert plain == b''
print(len(sealed))
PYCASE
