#!/usr/bin/env bash
# @testcase: usage-php83-r9-sign-detached-roundtrip
# @title: PHP sodium detached sign roundtrip
# @description: Generates an Ed25519 keypair via sodium_crypto_sign_keypair, signs a message with sodium_crypto_sign_detached, and verifies the signature against the public key.
# @timeout: 180
# @tags: usage, crypto, php
# @client: php8.3-cli

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

php <<'PHP'
<?php
$kp = sodium_crypto_sign_keypair();
$sk = sodium_crypto_sign_secretkey($kp);
$pk = sodium_crypto_sign_publickey($kp);
$msg = 'php detached sign r9 message';
$sig = sodium_crypto_sign_detached($msg, $sk);
if (strlen($sig) !== SODIUM_CRYPTO_SIGN_BYTES) { fwrite(STDERR, "bad sig length\n"); exit(1); }
if (!sodium_crypto_sign_verify_detached($sig, $msg, $pk)) { fwrite(STDERR, "verify failed\n"); exit(2); }
if (sodium_crypto_sign_verify_detached($sig, $msg . 'x', $pk)) { fwrite(STDERR, "verify wrongly succeeded\n"); exit(3); }
echo "ok\n";
PHP
