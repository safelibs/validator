#!/usr/bin/env bash
# @testcase: usage-python3-nacl-r14-pwhash-argon2i-str-verify
# @title: PyNaCl pwhash.argon2i.str hashes a password and verifies against the matching plaintext
# @description: Hashes a password with nacl.pwhash.argon2i.str at INTERACTIVE limits, asserts the resulting hash starts with the $argon2i$ prefix, calls nacl.pwhash.verify which must return True for the matching password, and asserts a different password raises InvalidkeyError.
# @timeout: 180
# @tags: usage, crypto, pwhash, argon2i, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import nacl.pwhash
from nacl.exceptions import InvalidkeyError

password = b"r14 argon2i password"
hashed = nacl.pwhash.argon2i.str(
    password,
    opslimit=nacl.pwhash.argon2i.OPSLIMIT_INTERACTIVE,
    memlimit=nacl.pwhash.argon2i.MEMLIMIT_INTERACTIVE,
)
assert isinstance(hashed, bytes)
assert hashed.startswith(b"$argon2i$"), hashed[:32]

assert nacl.pwhash.verify(hashed, password) is True

try:
    nacl.pwhash.verify(hashed, b"r14 wrong password")
except InvalidkeyError:
    print("ok", len(hashed))
else:
    raise SystemExit("wrong password unexpectedly verified")
PY
