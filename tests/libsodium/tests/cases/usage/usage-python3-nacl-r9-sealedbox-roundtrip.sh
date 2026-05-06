#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r9-sealedbox-roundtrip
# @title: PyNaCl SealedBox roundtrip
# @description: Generates a Curve25519 PrivateKey, encrypts a payload to its public key with SealedBox, and verifies the original private key decrypts the message.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.public import PrivateKey, SealedBox

sk = PrivateKey.generate()
pk = sk.public_key
sealed = SealedBox(pk).encrypt(b"sealed payload r9")
plain = SealedBox(sk).decrypt(sealed)
assert plain == b"sealed payload r9", plain
PY
