#!/usr/bin/env bash
# @testcase: usage-python3-nacl-signed-message-roundtrip
# @title: PyNaCl SignedMessage attached signature roundtrip
# @description: Signs a message with nacl.signing.SigningKey.sign, asserts the returned object is a nacl.signing.SignedMessage with the expected .message and 64-byte .signature attributes, that bytes(signed) is exactly signature || message (the libsodium attached-signature wire format), and that VerifyKey.verify accepts the attached form bytes(signed) and returns the original message bytes.
# @timeout: 180
# @tags: usage, crypto, signature, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.signing import SignedMessage, SigningKey

sk = SigningKey(b"\x55" * 32)
vk = sk.verify_key
message = b"signed message attached roundtrip"

signed = sk.sign(message)
assert isinstance(signed, SignedMessage)
assert signed.message == message
assert len(signed.signature) == 64

# bytes(signed) must equal signature || message (libsodium attached form).
attached = bytes(signed)
assert attached == signed.signature + signed.message
assert len(attached) == 64 + len(message)

# Verify accepts the attached bytes form and returns the original message.
recovered = vk.verify(attached)
assert recovered == message, recovered

# Verify also accepts (message, signature) form.
recovered2 = vk.verify(message, signed.signature)
assert recovered2 == message

print("ok", len(attached))
PY
