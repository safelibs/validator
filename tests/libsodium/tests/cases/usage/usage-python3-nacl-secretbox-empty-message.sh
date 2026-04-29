#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretbox-empty-message
# @title: PyNaCl SecretBox empty message
# @description: Encrypts and decrypts an empty payload with PyNaCl SecretBox and verifies the empty plaintext round trip.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-secretbox-empty-message"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.secret import SecretBox
box = SecretBox(b'7' * SecretBox.KEY_SIZE)
cipher = box.encrypt(b'')
plain = box.decrypt(cipher)
assert plain == b''
print(len(cipher))
PYCASE
