#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.public import Box, PrivateKey

alice_private = PrivateKey.generate()
bob_private = PrivateKey.generate()
alice_public = alice_private.public_key
bob_public = bob_private.public_key

plaintext = b"public box payload"
ciphertext = Box(alice_private, bob_public).encrypt(plaintext)
decrypted = Box(bob_private, alice_public).decrypt(ciphertext)
if decrypted != plaintext:
    raise SystemExit("PyNaCl public box plaintext did not round trip")
print(decrypted.decode())
PY
