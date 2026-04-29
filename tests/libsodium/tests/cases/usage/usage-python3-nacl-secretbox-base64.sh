#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretbox-base64
# @title: python3-nacl secretbox base64
# @description: Exercises python3-nacl secretbox base64 through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-secretbox-base64"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.encoding import Base64Encoder
from nacl.secret import SecretBox
box = SecretBox(b'5' * SecretBox.KEY_SIZE)
cipher = box.encrypt(b'base64 payload', encoder=Base64Encoder)
plain = box.decrypt(cipher, encoder=Base64Encoder)
assert plain == b'base64 payload'
print(cipher[:16].decode())
PYCASE
