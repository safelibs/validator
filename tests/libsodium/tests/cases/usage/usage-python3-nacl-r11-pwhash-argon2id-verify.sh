#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r11-pwhash-argon2id-verify
# @title: PyNaCl pwhash.argon2id.str then verify accepts and rejects passwords
# @description: Hashes a password with nacl.pwhash.argon2id.str at INTERACTIVE limits, asserts the resulting hash starts with the $argon2id$ prefix, verifies that the same password is accepted by nacl.pwhash.verify, and asserts a wrong password raises InvalidkeyError.
# @timeout: 180
# @tags: usage, crypto, python, pwhash
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.pwhash
from nacl.exceptions import InvalidkeyError

password = b"correct horse battery staple"
hashed = nacl.pwhash.argon2id.str(
    password,
    opslimit=nacl.pwhash.argon2id.OPSLIMIT_INTERACTIVE,
    memlimit=nacl.pwhash.argon2id.MEMLIMIT_INTERACTIVE,
)
assert isinstance(hashed, bytes)
assert hashed.startswith(b"$argon2id$"), hashed[:32]

assert nacl.pwhash.verify(hashed, password) is True

try:
    nacl.pwhash.verify(hashed, b"wrong password")
except InvalidkeyError:
    print("ok")
else:
    raise SystemExit("wrong password unexpectedly verified")
PY
