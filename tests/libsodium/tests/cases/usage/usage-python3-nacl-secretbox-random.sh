#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretbox-random
# @title: PyNaCl random secretbox
# @description: Encrypts and decrypts binary data with a random PyNaCl SecretBox key.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-secretbox-random"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.secret import SecretBox
from nacl.utils import random
payload = bytes(range(32))
box = SecretBox(random(SecretBox.KEY_SIZE))
cipher = box.encrypt(payload)
assert box.decrypt(cipher) == payload
print(len(cipher))
PY
