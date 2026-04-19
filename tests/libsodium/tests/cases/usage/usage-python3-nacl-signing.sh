#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
from nacl.signing import SigningKey
sk=SigningKey.generate(); signed=sk.sign(b'payload'); print(sk.verify_key.verify(signed).decode())
PY