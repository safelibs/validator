#!/usr/bin/env bash
# @testcase: usage-python3-nacl-signing
# @title: python3-nacl signing
# @description: Runs python3-nacl signing cryptography through libsodium.
# @timeout: 180
# @tags: usage, crypto
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
from nacl.signing import SigningKey
sk=SigningKey.generate(); signed=sk.sign(b'payload'); print(sk.verify_key.verify(signed).decode())
PY
