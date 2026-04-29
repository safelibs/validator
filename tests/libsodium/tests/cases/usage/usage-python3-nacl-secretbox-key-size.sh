#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretbox-key-size
# @title: python3 nacl secretbox key size
# @description: Reads the SecretBox.KEY_SIZE constant exposed by PyNaCl and verifies the 32-byte key length.
# @timeout: 180
# @tags: usage, python, secretbox
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-nacl-secretbox-key-size"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE'
from nacl.secret import SecretBox
assert SecretBox.KEY_SIZE == 32
print(SecretBox.KEY_SIZE)
PYCASE
