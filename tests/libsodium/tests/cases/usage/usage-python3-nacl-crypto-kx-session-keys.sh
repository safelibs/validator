#!/usr/bin/env bash
# @testcase: usage-python3-nacl-crypto-kx-session-keys
# @title: PyNaCl crypto_kx client/server session keys symmetry
# @description: Builds two libsodium kx keypairs through nacl.bindings.crypto_kx_keypair, derives client and server session keys with crypto_kx_client_session_keys and crypto_kx_server_session_keys, and asserts the sizes match crypto_kx_SESSIONKEYBYTES and that client_rx == server_tx and client_tx == server_rx.
# @timeout: 180
# @tags: usage, crypto, kx, python
# @client: python3-nacl

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
from nacl.bindings import (
    crypto_kx_PUBLIC_KEY_BYTES,
    crypto_kx_SECRET_KEY_BYTES,
    crypto_kx_SESSION_KEY_BYTES,
    crypto_kx_keypair,
    crypto_kx_client_session_keys,
    crypto_kx_server_session_keys,
)

client_pk, client_sk = crypto_kx_keypair()
server_pk, server_sk = crypto_kx_keypair()
assert len(client_pk) == crypto_kx_PUBLIC_KEY_BYTES
assert len(client_sk) == crypto_kx_SECRET_KEY_BYTES
assert len(server_pk) == crypto_kx_PUBLIC_KEY_BYTES
assert len(server_sk) == crypto_kx_SECRET_KEY_BYTES
assert client_pk != server_pk
assert client_sk != server_sk

client_rx, client_tx = crypto_kx_client_session_keys(client_pk, client_sk, server_pk)
server_rx, server_tx = crypto_kx_server_session_keys(server_pk, server_sk, client_pk)

assert len(client_rx) == crypto_kx_SESSION_KEY_BYTES
assert len(client_tx) == crypto_kx_SESSION_KEY_BYTES
assert len(server_rx) == crypto_kx_SESSION_KEY_BYTES
assert len(server_tx) == crypto_kx_SESSION_KEY_BYTES

# Client receives on the channel server transmits on, and vice versa.
assert client_rx == server_tx, "client_rx != server_tx"
assert client_tx == server_rx, "client_tx != server_rx"
# rx and tx within one side must differ for a kx pair.
assert client_rx != client_tx
print("ok", crypto_kx_SESSION_KEY_BYTES)
PY
