#!/usr/bin/env bash
# @testcase: usage-php83-r12-crypto-sign-detached-verify
# @title: PHP sodium_crypto_sign_detached produces verifiable Ed25519 signature
# @description: Builds a sign keypair from a fixed 32-byte seed, computes a detached Ed25519 signature over a fixed payload, asserts the signature length is SODIUM_CRYPTO_SIGN_BYTES, and verifies the signature against the corresponding public key.
# @timeout: 60
# @tags: usage, crypto, sign, ed25519, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php -r '
$seed = str_repeat("\x21", SODIUM_CRYPTO_SIGN_SEEDBYTES);
$kp = sodium_crypto_sign_seed_keypair($seed);
$pk = sodium_crypto_sign_publickey($kp);
$sk = sodium_crypto_sign_secretkey($kp);

$msg = "php r12 crypto_sign payload";
$sig = sodium_crypto_sign_detached($msg, $sk);
if (strlen($sig) !== SODIUM_CRYPTO_SIGN_BYTES) {
  fwrite(STDERR, "wrong sig len " . strlen($sig) . "\n"); exit(1);
}

if (!sodium_crypto_sign_verify_detached($sig, $msg, $pk)) {
  fwrite(STDERR, "verify failed\n"); exit(1);
}

// Tampered message must fail verify.
$tampered = $msg . "x";
if (sodium_crypto_sign_verify_detached($sig, $tampered, $pk)) {
  fwrite(STDERR, "tampered message accepted\n"); exit(1);
}
echo "ok\n";
'
