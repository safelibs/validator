#!/usr/bin/env bash
# @testcase: usage-python3-pbkdf2-kat
# @title: python3 pbkdf2_hmac known-answer
# @description: Derives a key with hashlib.pbkdf2_hmac against an RFC 6070 known-answer vector and verifies the hex digest exactly.
# @timeout: 180
# @tags: usage, python, crypto
# @client: python3-minimal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-pbkdf2-kat"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/out" <<'PY'
import hashlib
import sys

# RFC 6070 PBKDF2-HMAC-SHA1 vector:
#   P = "password", S = "salt", c = 4096, dkLen = 20
#   DK = 4b 00 79 01 b7 65 48 9a be ad 49 d9 26 f7 21 d0 65 a4 29 c1
dk = hashlib.pbkdf2_hmac("sha1", b"password", b"salt", 4096, 20)
with open(sys.argv[1], "w") as fh:
    fh.write(dk.hex() + "\n")
PY

expected='4b007901b765489abead49d926f721d065a429c1'
actual=$(cat "$tmpdir/out")
if [[ "$actual" != "$expected" ]]; then
  printf 'pbkdf2 known-answer mismatch:\n actual:   %s\n expected: %s\n' "$actual" "$expected" >&2
  exit 1
fi
