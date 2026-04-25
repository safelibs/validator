#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

case "$case_id" in
  usage-python3-nacl-sealed-box)
    python3 - <<'PY'
from nacl.public import PrivateKey, SealedBox
recipient = PrivateKey.generate()
sealed = SealedBox(recipient.public_key).encrypt(b"sealed payload")
plain = SealedBox(recipient).decrypt(sealed)
assert plain == b"sealed payload"
print(plain.decode())
PY
    ;;
  usage-python3-nacl-blake2b)
    python3 - <<'PY'
from nacl.hash import blake2b
from nacl.encoding import HexEncoder
digest = blake2b(b"payload", encoder=HexEncoder)
assert len(digest) == 64
print(digest[:16].decode())
PY
    ;;
  usage-python3-nacl-pwhash)
    python3 - <<'PY'
from nacl.pwhash import argon2id
salt = b"0" * argon2id.SALTBYTES
key = argon2id.kdf(32, b"password", salt, opslimit=argon2id.OPSLIMIT_MIN, memlimit=argon2id.MEMLIMIT_MIN)
assert len(key) == 32
print("key", len(key))
PY
    ;;
  usage-python3-nacl-verify-key-bytes)
    python3 - <<'PY'
from nacl.signing import SigningKey, VerifyKey
sk = SigningKey.generate()
signed = sk.sign(b"verify payload")
vk = VerifyKey(bytes(sk.verify_key))
assert vk.verify(signed) == b"verify payload"
print("verified")
PY
    ;;
  usage-python3-nacl-secretbox-nonce)
    python3 - <<'PY'
from nacl.secret import SecretBox
key = b"1" * SecretBox.KEY_SIZE
nonce = b"2" * SecretBox.NONCE_SIZE
box = SecretBox(key)
cipher = box.encrypt(b"nonce payload", nonce)
assert box.decrypt(cipher) == b"nonce payload"
print("nonce payload")
PY
    ;;
  usage-python3-nacl-sha256)
    python3 - <<'PY'
from nacl.hash import sha256
from nacl.encoding import HexEncoder
digest = sha256(b"abc", encoder=HexEncoder).decode()
assert digest == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
print(digest[:16])
PY
    ;;
  usage-python3-nacl-sign-seeded)
    python3 - <<'PY'
from nacl.signing import SigningKey
seed = b"\x01" * 32
signing_key = SigningKey(seed)
signed = signing_key.sign(b"seeded payload")
assert signing_key.verify_key.verify(signed) == b"seeded payload"
print(len(signed.signature))
PY
    ;;
  usage-python3-nacl-public-key-bytes)
    python3 - <<'PY'
from nacl.public import PrivateKey, PublicKey
private_key = PrivateKey.generate()
public_key = PublicKey(bytes(private_key.public_key))
assert bytes(public_key) == bytes(private_key.public_key)
print(len(bytes(public_key)))
PY
    ;;
  usage-python3-nacl-secretbox-random)
    python3 - <<'PY'
from nacl.secret import SecretBox
from nacl.utils import random
payload = bytes(range(32))
box = SecretBox(random(SecretBox.KEY_SIZE))
cipher = box.encrypt(payload)
assert box.decrypt(cipher) == payload
print(len(cipher))
PY
    ;;
  usage-php83-sodium-aead)
    php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_KEYBYTES);
$nonce = random_bytes(SODIUM_CRYPTO_AEAD_XCHACHA20POLY1305_IETF_NPUBBYTES);
$cipher = sodium_crypto_aead_xchacha20poly1305_ietf_encrypt('aead payload', 'ad', $nonce, $key);
$plain = sodium_crypto_aead_xchacha20poly1305_ietf_decrypt($cipher, 'ad', $nonce, $key);
if ($plain !== 'aead payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-pwhash)
    php <<'PHP'
<?php
$hash = sodium_crypto_pwhash_str('password', SODIUM_CRYPTO_PWHASH_OPSLIMIT_INTERACTIVE, SODIUM_CRYPTO_PWHASH_MEMLIMIT_INTERACTIVE);
if (!sodium_crypto_pwhash_str_verify($hash, 'password')) { exit(1); }
echo "password verified\n";
PHP
    ;;
  usage-php83-sodium-box)
    php <<'PHP'
<?php
$alice = sodium_crypto_box_keypair();
$bob = sodium_crypto_box_keypair();
$alice_to_bob = sodium_crypto_box_keypair_from_secretkey_and_publickey(sodium_crypto_box_secretkey($alice), sodium_crypto_box_publickey($bob));
$bob_from_alice = sodium_crypto_box_keypair_from_secretkey_and_publickey(sodium_crypto_box_secretkey($bob), sodium_crypto_box_publickey($alice));
$nonce = random_bytes(SODIUM_CRYPTO_BOX_NONCEBYTES);
$cipher = sodium_crypto_box('box payload', $nonce, $alice_to_bob);
$plain = sodium_crypto_box_open($cipher, $nonce, $bob_from_alice);
if ($plain !== 'box payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-sign-open)
    php <<'PHP'
<?php
$keypair = sodium_crypto_sign_keypair();
$signed = sodium_crypto_sign('signed payload', sodium_crypto_sign_secretkey($keypair));
$plain = sodium_crypto_sign_open($signed, sodium_crypto_sign_publickey($keypair));
if ($plain !== 'signed payload') { exit(1); }
echo $plain, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-shorthash)
    php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_SHORTHASH_KEYBYTES);
$hash = sodium_crypto_shorthash('payload', $key);
if (strlen($hash) !== SODIUM_CRYPTO_SHORTHASH_BYTES) { exit(1); }
echo sodium_bin2hex($hash), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-kdf)
    php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_KDF_KEYBYTES);
$subkey1 = sodium_crypto_kdf_derive_from_key(32, 1, 'CTXTEST1', $key);
$subkey2 = sodium_crypto_kdf_derive_from_key(32, 2, 'CTXTEST1', $key);
if (strlen($subkey1) !== 32 || strlen($subkey2) !== 32 || $subkey1 === $subkey2) { exit(1); }
echo strlen($subkey1), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-kx)
    php <<'PHP'
<?php
$client = sodium_crypto_kx_keypair();
$server = sodium_crypto_kx_keypair();
[$client_rx, $client_tx] = sodium_crypto_kx_client_session_keys($client, sodium_crypto_kx_publickey($server));
[$server_rx, $server_tx] = sodium_crypto_kx_server_session_keys($server, sodium_crypto_kx_publickey($client));
if ($client_rx !== $server_tx || $client_tx !== $server_rx) { exit(1); }
echo strlen($client_rx), PHP_EOL;
PHP
    ;;
  usage-php83-sodium-base64-roundtrip)
    php <<'PHP'
<?php
$encoded = sodium_bin2base64("payload\x00", SODIUM_BASE64_VARIANT_ORIGINAL);
$decoded = sodium_base642bin($encoded, SODIUM_BASE64_VARIANT_ORIGINAL);
if ($decoded !== "payload\x00") { exit(1); }
echo $encoded, PHP_EOL;
PHP
    ;;
  usage-php83-sodium-keyed-generichash)
    php <<'PHP'
<?php
$key = random_bytes(SODIUM_CRYPTO_GENERICHASH_KEYBYTES);
$hash = sodium_crypto_generichash('payload', $key, 16);
$other = sodium_crypto_generichash('other', $key, 16);
if (strlen($hash) !== 16 || $hash === $other) { exit(1); }
echo sodium_bin2hex($hash), PHP_EOL;
PHP
    ;;
  usage-libzmq5-curve-keypair)
    cat >"$tmpdir/t.c" <<'C'
#include <zmq.h>
#include <stdio.h>
#include <string.h>
int main(void) {
  char pub[41];
  char sec[41];
  if (zmq_curve_keypair(pub, sec) != 0) return 1;
  printf("curve-keypair %zu %zu\n", strlen(pub), strlen(sec));
  return (strlen(pub) == 40 && strlen(sec) == 40) ? 0 : 2;
}
C
    gcc "$tmpdir/t.c" -o "$tmpdir/t" $(pkg-config --cflags --libs libzmq)
    "$tmpdir/t"
    ;;
  usage-minisign-detached-text)
    printf 'detached minisign payload\n' >"$tmpdir/message.txt"
    minisign -G -p "$tmpdir/minisign.pub" -s "$tmpdir/minisign.sec" -W
    minisign -Sm "$tmpdir/message.txt" -s "$tmpdir/minisign.sec" -x "$tmpdir/message.minisig"
    minisign -Vm "$tmpdir/message.txt" -p "$tmpdir/minisign.pub" -x "$tmpdir/message.minisig" | tee "$tmpdir/out"
    validator_assert_contains "$tmpdir/out" 'Signature and comment signature verified'
    ;;
  *)
    printf 'unknown libsodium extra usage case: %s\n' "$case_id" >&2
    exit 2
    ;;
esac
