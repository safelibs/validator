#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r21-signing-verify-accepts-raw-bytes
# @title: python3-nacl VerifyKey.verify accepts raw 64-byte signature and message bytes
# @description: Signs a message with SigningKey, calls sign(...).signature to obtain raw 64-byte signature bytes, passes those bytes plus the original message to VerifyKey.verify, and asserts the returned value equals the original message, exercising libsodium Ed25519 raw-bytes verification path.
# @timeout: 60
# @tags: usage, sodium, signing, ed25519, python, r21
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.signing

sk = nacl.signing.SigningKey.generate()
vk = sk.verify_key
msg = b"verify raw bytes"
signed = sk.sign(msg)
sig = signed.signature
assert isinstance(sig, bytes), type(sig)
assert len(sig) == 64, len(sig)
out = vk.verify(msg, sig)
assert out == msg, out
print("ok sig_len=%d" % len(sig))
PY
