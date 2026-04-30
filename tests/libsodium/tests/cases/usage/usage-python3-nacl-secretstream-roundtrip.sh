#!/usr/bin/env bash
# @testcase: usage-python3-nacl-secretstream-roundtrip
# @title: PyNaCl secretstream xchacha20poly1305 roundtrip
# @description: Drives a multi-message crypto_secretstream_xchacha20poly1305 push/pull pair through PyNaCl bindings and asserts every chunk decrypts and the FINAL tag is observed.
# @timeout: 180
# @tags: usage, crypto, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.bindings import (
    crypto_secretstream_xchacha20poly1305_KEYBYTES,
    crypto_secretstream_xchacha20poly1305_TAG_MESSAGE,
    crypto_secretstream_xchacha20poly1305_TAG_FINAL,
    crypto_secretstream_xchacha20poly1305_keygen,
    crypto_secretstream_xchacha20poly1305_init_push,
    crypto_secretstream_xchacha20poly1305_init_pull,
    crypto_secretstream_xchacha20poly1305_push,
    crypto_secretstream_xchacha20poly1305_pull,
    crypto_secretstream_xchacha20poly1305_state,
)

key = crypto_secretstream_xchacha20poly1305_keygen()
assert len(key) == crypto_secretstream_xchacha20poly1305_KEYBYTES

push_state = crypto_secretstream_xchacha20poly1305_state()
header = crypto_secretstream_xchacha20poly1305_init_push(push_state, key)

messages = [b"first chunk", b"second chunk", b"final chunk"]
ad = b"validator-ad"
ciphertexts = []
for i, m in enumerate(messages):
    tag = (
        crypto_secretstream_xchacha20poly1305_TAG_FINAL
        if i == len(messages) - 1
        else crypto_secretstream_xchacha20poly1305_TAG_MESSAGE
    )
    ciphertexts.append(
        crypto_secretstream_xchacha20poly1305_push(push_state, m, ad, tag)
    )

pull_state = crypto_secretstream_xchacha20poly1305_state()
crypto_secretstream_xchacha20poly1305_init_pull(pull_state, header, key)

recovered = []
last_tag = None
for ct in ciphertexts:
    pt, last_tag = crypto_secretstream_xchacha20poly1305_pull(pull_state, ct, ad)
    recovered.append(pt)

assert recovered == messages, recovered
assert last_tag == crypto_secretstream_xchacha20poly1305_TAG_FINAL
print("ok", len(recovered))
PY
