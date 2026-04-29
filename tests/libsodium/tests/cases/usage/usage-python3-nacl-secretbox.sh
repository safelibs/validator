#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretbox
# @title: python3-nacl secretbox
# @description: Runs python3-nacl secretbox cryptography through libsodium.
# @timeout: 180
# @tags: usage, crypto
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
from nacl.secret import SecretBox
from nacl.utils import random
box=SecretBox(random(SecretBox.KEY_SIZE)); c=box.encrypt(b'payload'); print(box.decrypt(c).decode())
PY
